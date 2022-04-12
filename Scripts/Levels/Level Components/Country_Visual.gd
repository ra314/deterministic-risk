extends Node

var mask_sprite = null
var flashing = false
var time_since_last_flash = 0
const flashing_period = 0.5
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

var P = null
var Game_Manager = null

#UUI = Update User Interface
func init():
	P = get_parent()
	Game_Manager = P.Game_Manager
	P.connect("set_num_reinforcements", self, "UUI_num_reinforcements")
	if "pandemic" in Game_Manager.game_modes:
		P.connect("set_num_reinforcements", self, "UUI_pandemic")
		P.connect("set_num_troops", self, "UUI_pandemic")
	for status in P.statused:
		if status in Game_Manager.game_modes:
			P.connect("set_statused", self, "show_statused")
			break
	if "congestion" in Game_Manager.game_modes:
		P.connect("set_num_troops", self, "UUI_congestion")
		P.connect("set_num_reinforcements", self, "UUI_congestion")
		P.connect("set_max_troops", self, "UUI_congestion")
	# This is show UUI_num_troops doesn't interfere with UUI_congestion
	else:
		P.connect("set_num_troops", self, "UUI_num_troops")

func change_mask_color(color):
	# Performance hack
	# Don't bother creating mask sprite if one hasn't been created and the color of the country is grey
	# This is true for the majority of countries when the game is spawned
	if mask_sprite == null:
		if color == "gray":
			return
		else:
			create_mask_sprite()

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
	mask_shader.set_shader_param("u_color_key", Color(P.country_name))
	mask_shader.set_shader_param("u_highlight_color", Color8(255,255,255,255))
	mask_shader.set_shader_param("u_background_color", Color8(0,0,0,0))
	
	# Creating a sprite that contains the world's mask texture and add it to level
	var tex = ImageTexture.new()
	tex.create_from_image(P.Game_Manager.world_mask)
	
	mask_sprite = Sprite.new()
	mask_sprite.centered = false
	mask_sprite.texture = tex
	mask_sprite.visible = true
	mask_sprite.z_index = 4
	mask_sprite.set_material(mask_shader)
	# Scale after the shader has run to avoid AA issues
	mask_sprite.set_scale(Vector2(1/P.Game_Manager.scale_ratio,1/P.Game_Manager.scale_ratio))
	
	P.Game_Manager.add_child(mask_sprite)
	
	# Measuring performance
	var time_taken = OS.get_ticks_msec() - time_start
	return time_taken

####################
# Signals

func UUI_num_troops():
	$"Active Troops/Label".text = str(P.num_troops)

func UUI_pandemic():
	var num_deaths = P.calc_pandemic_deaths()
	$"Status/Num Pandemic".visible = num_deaths > 0
	$"Status/pandemic".visible = num_deaths > 0
	$"Status/Num Pandemic".text = str(num_deaths)

func show_statused(status_name, boolean):
	get_node("Status/" + status_name).visible = boolean

func UUI_congestion():
	$"Status/ProgressBar".max_value = P.max_troops
	$"Status/ProgressBar".value = P.num_troops+P.num_reinforcements
	# Updating the denominator
	show_congestion_denominator(denominator_showing)

func UUI_num_reinforcements():
	$"Reinforcements".visible = P.num_reinforcements > 0
	$"Reinforcements/Label".text = "+" + str(P.num_reinforcements)

# Signals
####################

var denominator_showing = false
func show_congestion_denominator(show_denominator_boolean):
	denominator_showing = show_denominator_boolean
	if show_denominator_boolean:
		$"Active Troops/Label".text = str(P.num_troops) + "/" + str(P.max_troops)
	else:
		$"Active Troops/Label".text = str(P.num_troops)

# The key is the other country that this line is connected to
# The value is an array of the country which is the parent of the line and the line itself
var lines = {}
func draw_line_to_country(selected_country):
	# Adding the line to the scene
	var new_line = Line2D.new()
	new_line.width = 2
	P.add_child(new_line)
	new_line.z_index = 10
	
	# Storing the drawn line
	lines[selected_country] = [P, new_line]
	selected_country.Visual.lines[P] = [P, new_line]
	
	# Connecting the points of the line
	new_line.add_point(Vector2(20,20))
	new_line.add_point(selected_country.position - P.position + Vector2(20,20))
func remove_line_to_country(selected_country):
	if not selected_country in lines:
		return false
	lines[selected_country][0].remove_child(lines[selected_country][1])
	lines[selected_country][1].free()
	
	# Removing the line node from storage
	lines.erase(selected_country)
	selected_country.Visual.lines.erase(P)
	
	return true
func remove_all_lines():
	for country in lines.keys():
		remove_line_to_country(country)

func move_to_location_with_duration(location, duration):
	$Tween.interpolate_property(P, "position", P.position, location, duration)

# Moving to a country and back
func move_to_country(destination_country):
	move_to_location_with_duration(destination_country.position, destination_movement_duration)
	$Tween.interpolate_callback(self, destination_movement_duration, "move_to_location_with_duration", P.position, origin_movement_duration)
	$Tween.start()

# Flash all countries that can be attacked
func flash_attackable_neighbours():
	for country in P.get_attackable_countries(Game_Manager.game_modes):
		# Creation of a mask sprite to do the flashing
		country.Visual.flashing = true

func stop_flashing():
	if flashing:
		change_mask_color(P.belongs_to.color)
		$"Active Troops/Sprite".modulate = Color(1,1,1)
		time_since_last_flash = 0
		flashing = false

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
				change_mask_color(P.belongs_to.color)
			toggle_brightness()
			time_since_last_flash = 0

