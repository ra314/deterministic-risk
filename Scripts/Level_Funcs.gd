extends Node2D

var Country = load("res://Scenes/Levels/Level Components/Country.tscn")
var all_countries = {}
var world_mask = null
var world_str = null
var world_sprite = null
var Player = load("res://Scenes/Levels/Level Components/Player.tscn")
# Player neutral is a dummy container for all of the unoccupied countries, 
# it simplifies the code when changing ownership and syncing ownership
var player_neutral = Player.instance().init("gray")

# This constant is the ratio between the maps current resolution and the screen resolution (1080p)
# For example the ratio between 4k and 1080p should be 2
const scale_ratio: float = 2.0

func create_default_level(level_node):	
	# Instantiating countries
	add_country_to_level(Country.instance().new(50, 50, "Alaska", player_neutral))
	add_country_to_level(Country.instance().new(100, 50, "West Canada", player_neutral))
	add_country_to_level(Country.instance().new(150, 70, "East Canada", player_neutral))
	add_country_to_level(Country.instance().new(100, 100, "USA", player_neutral))
	add_country_to_level(Country.instance().new(75, 150, "Mexico", player_neutral))
	add_country_to_level(Country.instance().new(120, 200, "Colombia", player_neutral))
	add_country_to_level(Country.instance().new(190, 200, "Brazil", player_neutral))
	add_country_to_level(Country.instance().new(170, 300, "Argentina", player_neutral))
	
	# Adding connections
	add_connections("Alaska", ["West Canada"])
	add_connections("West Canada", ["Alaska", "East Canada", "USA"])
	add_connections("East Canada", ["West Canada", "USA"])
	add_connections("USA", ["East Canada", "West Canada", "Mexico", "Colombia"])
	add_connections("Mexico", ["USA", "Colombia"])
	add_connections("Colombia", ["Mexico", "Brazil", "Argentina", "USA"])
	add_connections("Brazil", ["Colombia", "Argentina"])
	add_connections("Argentina", ["Colombia", "Brazil"])
	
	for country in all_countries.values():
		level_node.add_child(country)

func export_level(save_name):
	var save_game = File.new()
	save_game.open("res://" + save_name + ".save", File.WRITE)
	# Converting each country to a json and dumping them all
	var arr = all_countries.values()
	print(arr)
	arr.sort_custom(self, "country_comparator")
	for country in arr:
		save_game.store_line(to_json(country.save()))
	save_game.close()

func country_comparator(c1, c2):
	return c1.country_name < c2.country_name

func select_random(array):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return array[rng.randi() % len(array)]

func import_level(level_node, bool_load_countries):	
	# Instantiating countries
	var save_game = File.new()
	
	# Set up the save locations
	var worlds = ["Southern Seas", "Our World", "No Mans Land", "Isle of the Fyre", "Novingrad"]

	# Check if all the save files exist
	for world in worlds:
		if not save_game.file_exists("res://" + world + ".save"):
			print("res://" + world + ".save" + " Does not Exist")
			return false

	# Check if the selected world exists
	if not (world_str in worlds):
		print("The selected world string is not valid.")
		return false
	
	# Make visible the sprite of the selected world 
	world_sprite = Sprite.new()
	world_sprite.texture = load("res://Assets/Maps/" + world_str + ".png")
	world_sprite.visible = true
	world_sprite.scale = Vector2(0.5,0.5)
	world_sprite.centered = false
	world_sprite.z_index = -5
	level_node.add_child(world_sprite)
	
	# Get the location of the save
	var save_file_location = "res://" + world_str + ".save"
	
	# Load up the mask
	world_mask = load("res://Assets/Maps/" + world_str + " Mask.png").get_data()
	world_mask.lock()
	
	# Early return if asked to not load countries
	if not bool_load_countries:
		return true
	
	save_game.open(save_file_location, File.READ)
	
	# Going through the json save
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		var new_country = Country.instance().init(node_data["x"], node_data["y"], node_data["name"], player_neutral)
		add_country_to_level(new_country)
		level_node.add_child(new_country)
	
	# Adding connections
	save_game.open(save_file_location, File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		add_connections(node_data["name"], node_data["connections"])
	
	return true

# A line to visualize adjacent countries in the level creator
func draw_lines_between_countries():
	for country in all_countries.values():
		if country:
			if country.connected_countries:
				for neighbour in country.connected_countries:
					country.get_node("Visual").draw_line_to_country(neighbour)

func remove_lines_between_countries():
	for country in all_countries.values():
		for child in country.get_children():
			if child is Line2D:
				child.queue_free()

func add_country_to_level(country):
	all_countries[country.country_name] = country

func add_connections(source_country_name, destination_country_names):
	for destination_country_name in destination_country_names:
		all_countries[source_country_name].add_connection(all_countries[destination_country_name])

func get_color_in_mask(map_click_position):
	map_click_position *= scale_ratio
	return world_mask.get_pixel(map_click_position[0], map_click_position[1]).to_html()

