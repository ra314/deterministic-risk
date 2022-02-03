extends Node2D

var num_troops: int = 0
signal set_num_troops()
func set_num_troops(_num_troops):
	if Game_Manager:
		if "congestion" in Game_Manager.game_modes:
			if _num_troops > max_troops:
				return false
	num_troops = _num_troops
	emit_signal("set_num_troops")
	return true

var belongs_to = null
var connected_countries = []
var country_name = null
var Game_Manager = null
var Visual = null

var max_troops = 0
signal set_max_troops()
func set_max_troops(_max_troops):
	max_troops = _max_troops
	emit_signal("set_max_troops")

var statused = {"resistance": false, "blitzkrieg": false, "fatigue": false}
signal set_statused(status_name, boolean)
func set_statused(status_name, boolean):
	# Emit signal only if the boolean changes to save on performance
	if statused[status_name] != boolean:
		statused[status_name] = boolean
		emit_signal("set_statused", status_name, boolean)
# Does the country have at least one status
func is_statused():
	for status in statused:
		if statused[status]:
			return true
	return false

func get_raze_deaths():
	return floor(num_troops/2)

func raze():
	set_num_troops(num_troops - get_raze_deaths())
	reset_status()
	Game_Manager.set_selected_country(null)

func reset_status():
	for status in statused:
		set_statused(status, false)

# This is so during reinforcement the label can show up as
# {num_troops} + {num_reinforcements}
var num_reinforcements: int = 0
signal set_num_reinforcements()
# When check_player_reinforcements is false, we don't check if the player has enough reinforcements
# This is intended to be used for the movement phase, when it's not actually a reinforcement
func set_num_reinforcements(_num_reinforcements, check_player_reinforcements):
	if _num_reinforcements < 0:
		return false
	if "congestion" in Game_Manager.game_modes:
		if num_troops + _num_reinforcements > max_troops:
			return false
	if check_player_reinforcements:
		# Checking if the player doesn't have enough reinforcements
		if _num_reinforcements > (belongs_to.num_reinforcements + num_reinforcements):
			return false
		# Changing the number of reinforcements the player has
		belongs_to.num_reinforcements += num_reinforcements - _num_reinforcements
	num_reinforcements = _num_reinforcements
	emit_signal("set_num_reinforcements")
	return true

# Called when the node enters the scene tree for the first time.
func _ready():
	Game_Manager = get_parent()
	Visual = $Visual
	Visual.init()
	Visual.change_color_to(belongs_to.color)
	
	# The chunk below is for when the Country scene is called in isolation
	if Game_Manager.name == "Level Creator":
		var Player = load("res://Scenes/Levels/Level Components/Player.tscn")
		var player_neutral = Player.instance().init("gray")
		belongs_to = player_neutral
		return
	
	# Updating labels when number of troops change
	connect("set_num_troops", Game_Manager, "update_labels")
	connect("set_num_reinforcements", Game_Manager, "update_labels")
	
	# Turn on resistance when a country is conquered
	if "resistance" in Game_Manager.game_modes:
		connect("conquered", self, "set_statused", ["resistance", true])
		pass
	# Turn on fatigue when a country is attacking
	if "fatigue" in Game_Manager.game_modes:
		connect("attacking", self, "set_statused", ["fatigue", true])
	# Turn off blitz when is a country is conquered
	# Turn on blitz when a country is attacked
	if "blitzkrieg" in Game_Manager.game_modes:
		connect("conquered", self, "set_statused", ["blitzkrieg", false])
		connect("attacked", self, "set_statused", ["blitzkrieg", true])
	# Apply pandemic deaths when a turn is ended
	if "pandemic" in Game_Manager.game_modes:
		Game_Manager.Phase.connect("ending_reinforcement", self, "apply_pandemic_deaths")
	# Disabling resistance, blitz and similar volatile conditions
	Game_Manager.Phase.connect("ending_attack", self, "reset_status")
	# Reset reinforcements and move troops from reinforcement into active duty
	Game_Manager.Phase.connect("ending_reinforcement", self, "move_troops_to_active_duty")
	# Apply donations at the end of the movement phase
	if "movement" in Game_Manager.game_modes:
		Game_Manager.Phase.connect("ending_movement", self, "move_troops_to_active_duty")
		Game_Manager.Phase.connect("ending_movement", self, "destroy_donations")
	# Show a progressbar in congestion mode indiciating the max number of troops
	if "congestion" in Game_Manager.game_modes:
		$"Visual/Status/ProgressBar".visible = true

func move_troops_to_active_duty():
	set_num_troops(num_troops + num_reinforcements)
	set_num_reinforcements(0, false)

func change_ownership_to(player):
	# Transfer of Ownership
	belongs_to.owned_countries.erase(self)
	belongs_to = player
	player.owned_countries.append(self)
	# Visual Update
	Visual.change_color_to(player.color)
	Game_Manager.update_labels()

func calc_pandemic_deaths():
	var total = num_troops + num_reinforcements
	if total <= 3:
		return 0
	else:
		return int(ceil(float(total-3)/3))

func apply_pandemic_deaths():
	set_num_troops(num_troops - calc_pandemic_deaths())

static func can_attack(attacker, defender, game_modes):
	# Attack not possible if currently in resistance or fatigued
	if attacker.statused['resistance'] or attacker.statused['fatigue']:
		return false
	
	# Check if the defender and attacker are connected
	if defender in attacker.connected_countries:
		# Check if the defender and attacker had different owners
		if defender.belongs_to != attacker.belongs_to:
			# Check if the number of units is sufficient for an attack
			return (attacker.num_troops > defender.num_troops) or\
				(("drain" in game_modes) and (attacker.num_troops > 1))

func get_attackable_countries(game_modes):
	var attackable_countries = []
	for country in connected_countries:
		if can_attack(self, country, game_modes):
			attackable_countries.append(country)
	return attackable_countries

# Countries that can be attacked after performing a raze
func get_raze_and_attackable_countries(game_modes):
	# No countries can be attacked if the right game modes aren't selected
	if not ('raze' in game_modes):
		return []
	if (not ('resistance' in game_modes)) and (not ('fatigue' in game_modes)):
		return []
	
	var raze_and_attackable_countries = []
	
	# Perform a temporary raze
	var temp_statused = statused.duplicate()
	statused['resistance'] = false
	statused['fatigue'] = false
	var prev_num_troops = num_troops
	num_troops -= get_raze_deaths()
	
	for country in connected_countries:
		if can_attack(self, country, game_modes):
			raze_and_attackable_countries.append(country)
	
	# Undo the temporary raze
	statused = temp_statused
	num_troops = prev_num_troops
	return raze_and_attackable_countries

# The funciton below is triiggered when the collision shape is hit
func _input_event(viewport, event, shape_idx):
	if Game_Manager.name == "Level Creator":
		if event is InputEventMouseButton and not event.pressed:
			self.on_click(event.button_index, false)

signal attacked()
signal attacking()
func attacking():
	emit_signal("attacking")
signal conquered()
func on_click(event_index, is_long_press):	
	# Level Creator Behaviour
	if Game_Manager.name == "Level Creator":
		match Game_Manager.phase:
			"change curr troops":
				match event_index:
					BUTTON_LEFT:
						set_num_troops(num_troops+1)
					BUTTON_RIGHT:
						set_num_troops(num_troops-1)
			
			"add countries":
				# Country deletion
				if event_index == BUTTON_RIGHT:
					Game_Manager.all_countries.erase(country_name)
					for country in connected_countries:
						country.connected_countries.erase(self)
					queue_free()
			
			"connect countries":
				if Game_Manager.selected_country == null:
					Visual.toggle_brightness()
					Game_Manager.set_selected_country(self) 
				elif Game_Manager.selected_country == self:
					Visual.toggle_brightness()
					Game_Manager.set_selected_country(null) 
				else:
					connected_countries.append(Game_Manager.selected_country)
					Game_Manager.selected_country.connected_countries.append(self)
					if Game_Manager.lines_drawn:
						Visual.draw_line_to_country(Game_Manager.selected_country)
					Game_Manager.selected_country.Visual.toggle_brightness()
					Game_Manager.set_selected_country(null) 
			
			"move countries":
				Game_Manager.set_selected_country(self) 
			
			"add color to country":
				var color = str(Game_Manager.get_color_in_mask())
				for country in connected_countries:
					for i in len(country.connected_countries):
						if str(country.connected_countries[i].country_name) == str(country_name):
							country.connected_countries[i].country_name = color
				country_name = color
		
		return
	
	# In Game Behaviour
	Game_Manager.stop_flashing()
	
	# Do nothing if the game hasn't started
	if not Game_Manager.game_started:
		return
	
	# Deselecting behaviour
	if (Game_Manager.selected_country == self) and not is_long_press:
		Game_Manager.set_selected_country(null) 
		return
	
	match Game_Manager.phase:
		"attack":
			# If this country belongs to the current player, start flashing
			if belongs_to == Game_Manager.curr_player:
				Game_Manager.set_selected_country(self) 
				Visual.flash_attackable_neighbours()
			# Checking if there was a previous country selection
			elif Game_Manager.selected_country != null:
				var attacker = Game_Manager.selected_country
				# Check if this country is attackable by the attacker
				if can_attack(attacker, self, Game_Manager.game_modes):
					# If the attacker has more troops
					var delayed_conquer = false
					if attacker.num_troops > num_troops:
						var survivors = float(attacker.num_troops - num_troops)
						# The 2 vars below are the number of troops the defender and the attacker should get respectively
						# Of course this is subject to change with game modes, like congestion.
						var defender_troops = 0
						var attacker_troops = 0
						if "diffusion" in Game_Manager.game_modes:
							defender_troops = int(ceil(survivors/2))
							attacker_troops = 1+int(floor(survivors/2))
						else:
							defender_troops = survivors
							attacker_troops = 1
						
						if "congestion" in Game_Manager.game_modes:
							set_num_troops(min(defender_troops, max_troops))
							attacker.set_num_troops(min(attacker_troops, attacker.max_troops))
						else:
							set_num_troops(defender_troops)
							attacker.set_num_troops(attacker_troops)
						
						change_ownership_to(attacker.belongs_to)
						delayed_conquer = true
					
					# If it has less or equal and drain is one of the game modes
					elif "drain" in Game_Manager.game_modes:
						# Blitz Drain
						if statused["blitzkrieg"]:
							set_num_troops(num_troops - attacker.num_troops)
						# Normal Drain
						else:
							set_num_troops(num_troops - (attacker.num_troops - 1))
						attacker.set_num_troops(1)
						
						# Change ownership if drained to 0
						if num_troops == 0:
							change_ownership_to(Game_Manager.player_neutral)
							delayed_conquer = true
					
					# Common component between modes
					emit_signal("attacked")
					attacker.attacking()
					if delayed_conquer:
						emit_signal("conquered")
					Game_Manager.set_selected_country(null)
					
					# Movement animation
					attacker.Visual.move_to_country(self)
					
					# Phase change
					if Game_Manager.is_attack_over():
						Game_Manager.Phase.end_attack1(true)
					# Check if the opponent has any troops left
					if Game_Manager.get_next_player().get_num_troops() == 0:
						Game_Manager.end_game(belongs_to.color)

		"movement":
			if belongs_to != Game_Manager.curr_player:
				return
			if is_long_press and Game_Manager.selected_country == self:
				takeback_donations()
			else:
				if Game_Manager.selected_country == null:
					Game_Manager.set_selected_country(self)
				elif Game_Manager.selected_country in connected_countries:
					Game_Manager.selected_country.donate_to(self)

		"reinforcement":
			if belongs_to != Game_Manager.curr_player:
				return
			# Remove all reinforcements
			if is_long_press:
				set_num_reinforcements(0, true)
			# Add a reinforcement
			elif event_index == BUTTON_LEFT:
				set_num_reinforcements(num_reinforcements+1, true)
			# Remove a reinforcement
			elif event_index == BUTTON_RIGHT:
				set_num_reinforcements(num_reinforcements-1, true)
		
		"game over":
			pass

var donations = {}
func donate_to(country):
	# You can only donate if you have mroe than 1 troops
	if num_troops <= 1:
		return false
	# Moving the troops
	if not country.set_num_reinforcements(country.num_reinforcements+1, false):
		return false
	set_num_troops(num_troops - 1)
	# Drawing the line and providing donations
	if not country in donations:
		donations[country] = 1
		Visual.draw_line_to_country(country)
	else:
		donations[country] += 1
	return true
func takeback_donations():
	var troop_total = 0
	for country in donations:
		# Take the donation away
		country.set_num_reinforcements(country.num_reinforcements - donations[country], false)
		# Keeping score of the donations taken back
		troop_total += donations[country]
	# Putting all donations taken back, back into deployment
	set_num_troops(num_troops + troop_total)
	destroy_donations()
func destroy_donations():
	Visual.remove_all_lines()
	donations = {}

func add_connection(country):
	connected_countries.append(country)

# Randomise num_troops
func randomise_troops():
	# Distribution 1: 0.5, 2: 0.3, 3: 0.1, 4: 0.1
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rand_num = rng.randf_range(0,10)
	var new_num_troops = 0
	if rand_num < 5:
		new_num_troops = 1
	elif rand_num < 8:
		new_num_troops = 2
	elif rand_num < 9:
		new_num_troops = 3
	elif rand_num < 10:
		new_num_troops = 4
	set_initial_troops(new_num_troops)

func set_initial_troops(_num_troops):
	set_max_troops(_num_troops*2)
	set_num_troops(_num_troops)


func init(_x, _y, _country_name, player):
	self.belongs_to = player
	position = Vector2(_x, _y)
	self.country_name = _country_name
	randomise_troops()
	return self

# Synchronise the country over network
func synchronise(_num_troops, _num_reinforcements, _belongs_to, _statused, _max_troops):
	set_num_troops(_num_troops)
	for key in _statused:
		set_statused(key, _statused[key])
	set_max_troops(_max_troops)
	set_num_reinforcements(_num_reinforcements, false)
	if belongs_to != _belongs_to:
		change_ownership_to(_belongs_to)

func save_level_creator():
	var save_dict = {}
	save_dict["name"] = country_name
	save_dict["troops"] = num_troops
	save_dict["x"] = position[0]
	save_dict["y"] = position[1]
	save_dict["connections"] = []
	for country in connected_countries:
		save_dict["connections"].append(country.country_name)
	return save_dict

func save():
	var save_dict = {}
	save_dict["name"] = country_name
	save_dict["troops"] = num_troops
	save_dict["max_troops"] = max_troops
	save_dict["status"] = statused
	save_dict["owner_color"] = belongs_to.color
	return save_dict
