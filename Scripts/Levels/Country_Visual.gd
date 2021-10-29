extends Node

var mask_sprite = null
var flashing = false
var time_since_last_flash = 0
const flashing_period = 0.5
var suffix = ""
var colors = {"blue": load("res://Assets/blue-square.svg"), 
				"red": load("res://Assets/red-pentagon.svg"),
				"gray": load("res://Assets/neutral-circle.svg")}
const mask_colors = {"white": Color8(255,255,255,255),
					"blue": Color8(70,70,185,255),
					"red": Color8(195,60,60,255),
					"gray": Color8(165,165,165,255)}
# Time to take to move during the attack animation
const destination_movement_duration = 0.2
const origin_movement_duration = 0.4

var Game_Manager = null

func change_mask_color(color):
	# Performance hack
	# Don't bother creating mask sprite if one hasn't been created and the color of the country is grey
	# This is true for the majority of countries when the game is spawned
	if mask_sprite == null:
		if color == "gray":
			return
		else:
			print(str(create_mask_sprite()) + "ms")

	var shader = mask_sprite.get_material()
	shader.set_shader_param("u_highlight_color", mask_colors[color])
	mask_sprite.set_material(shader)

func change_color_to(color):
	$"Active Troops/Sprite".texture = colors[color]
	$"Reinforcements/Sprite".texture = colors[color]
	change_mask_color(color)

func create_mask_sprite():
	# Measuring performance
	var time_start = OS.get_ticks_msec()
	
	# Changing the select country to white and everything else to transparent
	var mask_shader = load("res://Assets/mask_shader.tres").duplicate()
	mask_shader.set_shader_param("u_color_key", Color(get_parent().country_name))
	mask_shader.set_shader_param("u_highlight_color", Color8(255,255,255,255))
	mask_shader.set_shader_param("u_background_color", Color8(0,0,0,0))
	
	# Creating a sprite that contains the world's mask texture and add it to level
	var tex = ImageTexture.new()
	tex.create_from_image(get_parent().Game_Manager.world_mask)
	
	mask_sprite = Sprite.new()
	mask_sprite.centered = false
	mask_sprite.texture = tex
	mask_sprite.visible = true
	mask_sprite.z_index = 4
	mask_sprite.set_material(mask_shader)
	# Scale after the shader has run to avoid AA issues
	mask_sprite.set_scale(Vector2(1/get_parent().Game_Manager.scale_ratio,1/get_parent().Game_Manager.scale_ratio))
	
	get_parent().Game_Manager.add_child(mask_sprite)
	
	# Measuring performance
	var time_taken = OS.get_ticks_msec() - time_start
	return time_taken

func update_labels():
	$"Active Troops/Label".text = str(get_parent().num_troops)

	$"Reinforcements".visible = get_parent().num_reinforcements > 0
	$"Reinforcements/Label".text = "+" + str(get_parent().num_reinforcements)
	
	if Game_Manager:
		if "pandemic" in Game_Manager.game_modes:
			var num_deaths = get_parent().calc_pandemic_deaths()
			$"Status/Num Pandemic".visible = num_deaths > 0
			$"Status/Pandemic".visible = num_deaths > 0
			$"Status/Num Pandemic".text = str(num_deaths)
		if "blitzkrieg" in Game_Manager.game_modes:
			$"Status/Blitz".visible = get_parent().statused["Blitz"]
		if "fatigue" in Game_Manager.game_modes:
			$"Status/Fatigue".visible = get_parent().statused["Fatigue"]
		if "congestion" in Game_Manager.game_modes:
			$"Status/ProgressBar".value = get_parent().num_troops+get_parent().num_reinforcements
			if Game_Manager.show_denominator:
				$"Active Troops/Label".text += suffix
		Game_Manager.update_labels()

func draw_line_to_country(selected_country):
	var new_line = Line2D.new()
	add_child(new_line)
	new_line.add_point(Vector2(20,20))
	new_line.add_point(selected_country.position - get_parent().position + Vector2(20,20))

func move_to_location_with_duration(location, duration):
	$Tween.interpolate_property(get_parent(), "position", get_parent().position, location, duration)

# Moving to a country and back
func move_to_country(destination_country):
	move_to_location_with_duration(destination_country.position, destination_movement_duration)
	$Tween.interpolate_callback(self, destination_movement_duration, "move_to_location_with_duration", get_parent().position, origin_movement_duration)
	$Tween.start()

# Flash all countries that can be attacked
func flash_attackable_neighbours():
	for country in get_parent().get_attackable_countries(Game_Manager.game_modes):
		# Creation of a mask sprite to do the flashing
		country.get_node("Visual").flashing = true

func stop_flashing():
	change_mask_color(get_parent().belongs_to.color)
	$"Active Troops/Sprite".modulate = Color(1,1,1)
	time_since_last_flash = 0
	self.flashing = false

func toggle_brightness():
	if $"Active Troops/Sprite".modulate == Color(1,1,1):
		$"Active Troops/Sprite".modulate = Color(0.5,0.5,0.5)
	else:
		$"Active Troops/Sprite".modulate = Color(1,1,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flashing:
		time_since_last_flash += delta
		if time_since_last_flash > flashing_period:
			#Flashing the country sprite
			if $"Active Troops/Sprite".modulate == Color(1,1,1):
				change_mask_color("white")
			else:
				change_mask_color(get_parent().belongs_to.color)
			toggle_brightness()
			time_since_last_flash = 0

