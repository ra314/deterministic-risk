extends Area2D

var num_troops = 0
var belongs_to = null
var connected_countries = []
var country_name = null
var Game_Manager = null

var flashing = false
var time_since_last_flash = 0
var flashing_period = 0.5
var flash_mask_sprite = null

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

func change_ownership_to(player):
	# Transfer of Ownership
	if belongs_to != null:
		belongs_to.owned_countries.erase(self)
	belongs_to = player
	
	if player != null:
		player.owned_countries.append(self)
		# Visual Update
		player.update_labels()
		get_node("Sprite").change_color_to(player.color)
	else:
		get_node("Sprite").change_color_to("gray")

func update_labels():
	get_node("Label").text = str(num_troops)
	if belongs_to:
		belongs_to.update_labels()

func flash_attackable_neighbours(player):
	for country in connected_countries:
		if not country.flash_mask_sprite:
			print(str(country.create_flash_mask_sprite()) + "ms")
	
	for country in connected_countries:
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
		match Game_Manager.phase:
			"change curr troops":
				match event.button_index:
					BUTTON_LEFT:
						num_troops += 1
					BUTTON_RIGHT:
						num_troops -=1
			
			"add countries":
				if event.button_index == BUTTON_RIGHT:
					Game_Manager.all_countries.erase(self)
					queue_free()
			
			"connect countries":
				if Game_Manager.selected_country == null:
					Game_Manager.selected_country = self
				elif Game_Manager.selected_country != self:
					connected_countries.append(Game_Manager.selected_country)
					Game_Manager.selected_country.connected_countries.append(self)
					draw_line_to_country(Game_Manager.selected_country)
					Game_Manager.selected_country = null
			
			"move countries":
				Game_Manager.selected_country = self
			
			"add color to country":
				var color = Game_Manager.get_color_in_mask()[0]
				for country in connected_countries:
					for i in len(country.connected_countries):
						if country.connected_countries[i].country_name == country_name:
							country.connected_countries[i].country_name = color
				country_name = color
		
		update_labels()
		return
	
	Game_Manager.stop_flashing()
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
	update_labels()

func init(_x, _y, _country_name):
	position = Vector2(_x, _y)
	self.country_name = _country_name
	randomise_troops()
	return self

# Called when the node enters the scene tree for the first time.
func _ready():
	Game_Manager = get_parent()
	update_labels()

func stop_flashing():
	if flash_mask_sprite != null:
		flash_mask_sprite.visible = false
		#print(flash_mask_sprite.visible)
	get_node("Sprite").modulate = Color(1,1,1)
	time_since_last_flash = 0
	self.flashing = false

# Synchronise the country over network
func synchronise(_num_troops, _belongs_to):
	num_troops = _num_troops
	if belongs_to != _belongs_to:
		change_ownership_to(_belongs_to)
	update_labels()

func create_flash_mask_sprite():
	# Measuring performance
	var time_start = OS.get_ticks_msec()
	
	# Creating a sprite that contains the world's mask texture and add it to level
	flash_mask_sprite = Sprite.new()
	flash_mask_sprite.set_scale(Vector2(0.5,0.5))
	flash_mask_sprite.centered = false
	var tex = ImageTexture.new()
	tex.create_from_image(Game_Manager.world_mask)
	flash_mask_sprite.texture = tex
	Game_Manager.add_child(flash_mask_sprite)

	# Changing the select country to white and everything else to transparent
	var flash_shader = Game_Manager.flash_shader.duplicate()
	flash_shader.set_shader_param("u_color_key", Color8(country_name,country_name,country_name,255))
	flash_shader.set_shader_param("u_highlight_color", Color8(255,255,255,255))
	flash_shader.set_shader_param("u_background_color", Color8(0,0,0,0))
	flash_mask_sprite.set_material(flash_shader)
	
	# Measuring performance
	var time_taken = OS.get_ticks_msec() - time_start
	#print(str(time_taken) + "ms")
	return time_taken

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flashing:
		time_since_last_flash += delta
		if time_since_last_flash > flashing_period:
#			# Spawning the mask sprite if it doesn't exist
#			if flash_mask_sprite == null:
#				create_flash_mask_sprite()
			#Flashing the mask
			#print(flash_mask_sprite.visible)
			flash_mask_sprite.visible = !flash_mask_sprite.visible
			
			#Flashing the country sprite
			if get_node("Sprite").modulate == Color(1,1,1):
				get_node("Sprite").modulate = Color(0.5,0.5,0.5)
			else:
				get_node("Sprite").modulate = Color(1,1,1)
			time_since_last_flash = 0
