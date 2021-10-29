extends Node2D

var num_troops: int = 0
var belongs_to = null
var connected_countries = []
var country_name = null
var Game_Manager = null

var max_troops = 0
var statused = {"Fatigue": false, "Blitz": false, "Pandemic": false}

# This is so during reinforcement the label can show up as
# {num_troops} + {num_reinforcements}
var num_reinforcements: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() is Viewport:
		print("happened")
		var Player = load("res://Scenes/Levels/Level Components/Player.tscn")
		var player_neutral = Player.instance().init("gray")
		belongs_to = player_neutral
	
	Game_Manager = get_parent()
	$Visual.Game_Manager = Game_Manager
	$Visual.change_color_to(belongs_to.color)


func change_ownership_to(player):
	# Transfer of Ownership
	belongs_to.owned_countries.erase(self)
	belongs_to = player
	player.owned_countries.append(self)
	
	# Visual Update
	# If statement is present in case the country scene is run without a game manager
	if Game_Manager:
		Game_Manager.update_labels()
	$Visual.change_color_to(player.color)
	$Visual.update_labels()

func reset_status():
	# Enable fatigue and remove blitz
	if "fatigue" in Game_Manager.game_modes:
		statused["Fatigue"] = true
	if "blitzkrieg" in Game_Manager.game_modes:
		statused["Blitz"] = false

func calc_pandemic_deaths():
	var total = num_troops + num_reinforcements
	if total <= 3:
		return 0
	else:
		return int(ceil(float(total-3)/3))

static func can_attack(attacker, defender, game_modes):
	# Attack not possible if currently fatigued
	if "fatigue" in game_modes and attacker.statused['Fatigue'] == true:
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

func _input_event(viewport, event, shape_idx):
	if get_tree().get_current_scene().get_name() == "Level Creator":
		if event is InputEventMouseButton and not event.pressed:
			self.on_click(event, false)

func on_click(event, is_long_press):	
	# Level Creator Behaviour
	if get_tree().get_current_scene().get_name() == "Level Creator":
		match Game_Manager.phase:
			"change curr troops":
				match event.button_index:
					BUTTON_LEFT:
						num_troops += 1
					BUTTON_RIGHT:
						num_troops -=1
			
			"add countries":
				# Country deletion
				if event.button_index == BUTTON_RIGHT:
					Game_Manager.all_countries.erase(country_name)
					for country in connected_countries:
						print(country.name)
						country.connected_countries.erase(self)
					queue_free()
			
			"connect countries":
				print(Game_Manager.selected_country)
				if Game_Manager.selected_country == null:
					$Visual.toggle_brightness()
					Game_Manager.selected_country = self
				elif Game_Manager.selected_country == self:
					$Visual.toggle_brightness()
					Game_Manager.selected_country = null
				else:
					connected_countries.append(Game_Manager.selected_country)
					Game_Manager.selected_country.connected_countries.append(self)
					if Game_Manager.lines_drawn:
						$Visual.draw_line_to_country(Game_Manager.selected_country)
					Game_Manager.selected_country.get_node("Visual").toggle_brightness()
					Game_Manager.selected_country = null
				print(Game_Manager.selected_country)
			
			"move countries":
				Game_Manager.selected_country = self
			
			"add color to country":
				var color = str(Game_Manager.get_color_in_mask())
				for country in connected_countries:
					for i in len(country.connected_countries):
						if str(country.connected_countries[i].country_name) == str(country_name):
							country.connected_countries[i].country_name = color
				country_name = color
		
		$Visual.update_labels()
		return
	
	# In Game Behaviour
	
	# Don't do anything in multiplayer mode if the player of this game instance isn't the curr player
	if Game_Manager._root.online_game:
		print(Game_Manager.curr_player.network_id)
		print(Game_Manager._root.players[Game_Manager._root.player_name])
		if Game_Manager.curr_player.network_id != Game_Manager._root.players[Game_Manager._root.player_name]:
			return
	
	Game_Manager.stop_flashing()
	
	# Do nothing if the game hasn't started
	if not Game_Manager.game_started:
		return
	
	# Deselecting behaviour
	if Game_Manager.selected_country == self:
		Game_Manager.selected_country = null
		return
	
	match Game_Manager.phase:
		"attack":
			# If this country belongs to the current player, start flashing
			if belongs_to == Game_Manager.curr_player:
				Game_Manager.selected_country = self
				Game_Manager.flash_across_network(country_name)
			# Checking if there was a previous country selection
			elif Game_Manager.selected_country != null:
				var attacker = Game_Manager.selected_country
				# Check if this country is attackable by the attacker
				if can_attack(attacker, self, Game_Manager.game_modes):
					# Updating variables
					# If the attacker has more troops
					if attacker.num_troops > num_troops:
						var survivors = float(attacker.num_troops - num_troops)
						if "diffusion" in Game_Manager.game_modes:
							num_troops = int(ceil(survivors/2))
							attacker.num_troops = 1+int(floor(survivors/2))
						else:
							num_troops = survivors
							attacker.num_troops = 1
						
						if "congestion" in Game_Manager.game_modes:
							num_troops = min(num_troops, max_troops)
							attacker.num_troops = min(attacker.num_troops, attacker.max_troops)
							
						change_ownership_to(attacker.belongs_to)
						reset_status()
					# If it has less or equal and drain is one of the game modes
					elif "drain" in Game_Manager.game_modes:
						# Blitz Drain
						if statused["Blitz"]:
							num_troops -= (attacker.num_troops)
						# Normal Drain
						else:
							num_troops -= (attacker.num_troops - 1)
						
						attacker.num_troops = 1
						
						if "blitzkrieg" in Game_Manager.game_modes:
							statused["Blitz"] = true
						
						# Change ownership if drained to 0
						if num_troops == 0:
							change_ownership_to(Game_Manager.player_neutral)
							reset_status()
						
					# Common component between modes
					$Visual.update_labels()
					attacker.get_node("Visual").update_labels()
					Game_Manager.selected_country = null
					
					# Movement animation
					Game_Manager.move_country_across_network(attacker.country_name, country_name)
					
					# Phase change
					if Game_Manager.is_attack_over():
						Game_Manager.change_to_reinforcement(true)
					# Check if the opponent has any troops left
					if Game_Manager.get_next_player().get_num_troops() == 0:
						Game_Manager.end_game(belongs_to.color)


		"reinforcement":
			if belongs_to == Game_Manager.curr_player:
				# Add a reinforcement
				if event.button_index == BUTTON_LEFT:
					# Check that the player has reinforcements available to allocate
					if Game_Manager.curr_player.num_reinforcements > 0:
						if "congestion" in Game_Manager.game_modes:
							if (num_reinforcements + num_troops) < max_troops:
								Game_Manager.curr_player.num_reinforcements -= 1
								num_reinforcements += 1
						else:
							Game_Manager.curr_player.num_reinforcements -= 1
							num_reinforcements += 1
				# Remove a reinforcement
				elif event.button_index == BUTTON_RIGHT:
					# Check that a reinforcement has been previously added to this country
					if num_reinforcements > 0:
						num_reinforcements -= 1
						Game_Manager.curr_player.num_reinforcements += 1
				elif is_long_press:
					# Remove all reinforcements
					if num_reinforcements > 0:
						Game_Manager.curr_player.num_reinforcements += num_reinforcements
						num_reinforcements = 0
				
				$Visual.update_labels()
				Game_Manager.update_labels()
			pass
		
		"game over":
			pass

func add_connection(country):
	connected_countries.append(country)

# Randomise num_troops
func randomise_troops():
	# Distribution 1: 0.5, 2: 0.3, 3: 0.1, 4: 0.1
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rand_num = rng.randf_range(0,10)
	if rand_num < 5:
		num_troops = 1
	elif rand_num < 8:
		num_troops = 2
	elif rand_num < 9:
		num_troops = 3
	elif rand_num < 10:
		num_troops = 4
	$Visual.update_labels()

func init(_x, _y, _country_name, player):
	self.belongs_to = player
	position = Vector2(_x, _y)
	self.country_name = _country_name
	randomise_troops()
	$Visual.update_labels()
	return self

func get_sync_data():
	var sync_data = {}
	sync_data[num_troops] = num_troops
	sync_data[num_reinforcements] = num_reinforcements
	sync_data[belongs_to] = belongs_to.color
	sync_data[statused] = statused
	sync_data[max_troops] = max_troops
#	sync_data[suffix] = $Visual.suffix

# Synchronise the country over network
func synchronise(_num_troops, _num_reinforcements, _belongs_to, _statused, _max_troops, _suffix):
	num_troops = _num_troops
	num_reinforcements = _num_reinforcements
	statused = _statused
	max_troops = _max_troops
	$Visual.suffix = _suffix
	if belongs_to != _belongs_to:
		change_ownership_to(_belongs_to)
	$Visual.update_labels()

func save():
	var save_dict = {}
	save_dict["name"] = country_name
	save_dict["troops"] = num_troops
	save_dict["x"] = position[0]
	save_dict["y"] = position[1]
	save_dict["connections"] = []
	for country in connected_countries:
		save_dict["connections"].append(country.country_name)
	return save_dict
