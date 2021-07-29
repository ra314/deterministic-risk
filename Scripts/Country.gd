extends Area2D

var num_troops = 0
var belongs_to = null
var connected_countries = []
var country_name = null
var Game_Manager = null

var flashing = false
var time_since_last_flash = 0
var flashing_period = 0.5

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
	
func _input_event(viewport, event, shape_idx):
	if event.is_pressed():
		self.on_click(event)

func change_ownership_to(player):
	# Transfer of Ownership
	if belongs_to != null:
		belongs_to.owned_countries.erase(self)
	belongs_to = player
	player.owned_countries.append(self)
	
	# Visual Update
	player.update_labels()
	get_node("Sprite").change_color_to(player.color)

func update_labels():
	# Level Creator Behaviour
	if get_tree().get_current_scene().get_name() == "Level Creator":
		get_node("Label").text = str(num_troops)
		return
	get_node("Label").text = str(num_troops)
	if belongs_to:
		belongs_to.update_labels()

func flash_attackable_neighbours(player):
	for country in connected_countries:
		print(country.country_name)
		if country.belongs_to != player:
			country.flashing = true

func draw_line_to_country(selected_country):
	var new_line = Line2D.new()
	add_child(new_line)
	new_line.add_point(Vector2(0,0))
	new_line.add_point(selected_country.position - position)

func can_attack():
	for country in connected_countries:
		if country.num_troops < num_troops and country.belongs_to != belongs_to:
			return true
	return false
	

func on_click(event):
	# Level Creator Behaviour
	if get_tree().get_current_scene().get_name() == "Level Creator":
		match get_parent().phase:
			"change curr troops":
				match event.button_index:
					BUTTON_LEFT:
						num_troops += 1
					BUTTON_RIGHT:
						num_troops -=1
			
			"add countries":
				if event.button_index == BUTTON_RIGHT:
					get_parent().all_countries.erase(self)
					queue_free()
			
			"connect countries":
				if get_parent().selected_country == null:
					get_parent().selected_country = self
				elif get_parent().selected_country != self:
					connected_countries.append(get_parent().selected_country)
					get_parent().selected_country.connected_countries.append(self)
					draw_line_to_country(get_parent().selected_country)
					get_parent().selected_country = null
		
		update_labels()
		return
	
	get_parent().stop_flashing()
	match Game_Manager.phase:
		"attack":
			if belongs_to != Game_Manager.curr_player:
				# If you select a country that's not your own with a previous country selection
				if Game_Manager.selected_country != null:
					# And if it is a neighbour, then attack
					if Game_Manager.selected_country in connected_countries:
						var attacker = Game_Manager.selected_country
						if attacker.num_troops > num_troops:
							num_troops = attacker.num_troops - num_troops
							attacker.num_troops = 1
							update_labels()
							attacker.update_labels()
							
							change_ownership_to(attacker.belongs_to)
							if Game_Manager.is_attack_over():
								Game_Manager.change_to_reinforcement()
							
							Game_Manager.selected_country = null
							
							# Check if the opponent has any troops left
							if Game_Manager.get_next_player().get_num_troops() == 0:
								Game_Manager.end_game()
				return

		"reinforcement":
			if belongs_to == Game_Manager.curr_player:
				# Add a reinforcement
				if event.button_index == BUTTON_LEFT and Game_Manager.curr_player.num_reinforcements > 0:
					num_troops += 1
					Game_Manager.curr_player.num_reinforcements -= 1
					if self in Game_Manager.reinforced_countries:
						Game_Manager.reinforced_countries[self] += 1
					else:
						Game_Manager.reinforced_countries[self] = 1
					
					# Changing to attack phase for the next player
					if Game_Manager.curr_player.num_reinforcements == 0:
						Game_Manager.change_to_attack()
				
				# Remove a reinforcement
				if event.button_index == BUTTON_RIGHT:
					# Check that a reinforcement has been previously added to this country
					if self in Game_Manager.reinforced_countries and Game_Manager.reinforced_countries[self] > 0:
						num_troops -= 1
						Game_Manager.curr_player.num_reinforcements += 1
						if self in Game_Manager.reinforced_countries:
							Game_Manager.reinforced_countries[self] -= 1
				
				update_labels()
				Game_Manager.curr_player.update_labels()
			return
		
		"game over":
			return
		
	Game_Manager.selected_country = self	
	flash_attackable_neighbours(Game_Manager.curr_player)

func add_connection(country):
	connected_countries.append(country)

# Randomise num_troops
func randomise_troops():
	# Distribution 1: 0.5, 2: 0.3, 3: 0.1, 4: 0.1
	# TODO, HAVE A STATIC GLOBAL rng
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

func init(_x, _y, _country_name):
	position = Vector2(_x, _y)
	self.country_name = _country_name
	randomise_troops()
	return self

# Called when the node enters the scene tree for the first time.
func _ready():
	Game_Manager = get_parent().get_parent()
	update_labels()

func stop_flashing():
	get_node("Sprite").modulate = Color(1,1,1)
	time_since_last_flash = 0
	self.flashing = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flashing:
		time_since_last_flash += delta
		if time_since_last_flash > flashing_period:
			if get_node("Sprite").modulate == Color(1,1,1):
				get_node("Sprite").modulate = Color(0.5,0.5,0.5)
			else:
				get_node("Sprite").modulate = Color(1,1,1)
			time_since_last_flash = 0