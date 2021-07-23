extends Node
var Country = load("res://Country.tscn")
var all_countries = {}
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func import_level():
	var save_game = File.new()
	save_game.open("res://savegame.save", File.READ)
	
	# Instantiating countries
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		var new_country = Country.instance().init(node_data["x"], node_data["y"], node_data["name"])
		add_country_to_level(new_country)
		add_child(new_country)
	
	# Adding connections
	save_game.open("res://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		add_connections(node_data["name"], node_data["connections"])

func add_connections(source_country_name, destination_country_names):
	for destination_country_name in destination_country_names:
		all_countries[source_country_name].add_connection(all_countries[destination_country_name])

func add_country_to_level(country):
	all_countries[country.country_name] = country
	
func stop_flashing():
	for country in all_countries.values():
		country.stop_flashing()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_size(Vector2(1920, 1080))
	
	#Loading existing level
	var save_game = File.new()
	if save_game.file_exists("res://savegame.save"):
		import_level()
	return
	
	# America
	add_country_to_level(Country.instance().init(50, 50, "Alaska"))
	add_country_to_level(Country.instance().init(100, 50, "West Canada"))
	add_country_to_level(Country.instance().init(150, 70, "East Canada"))
	add_country_to_level(Country.instance().init(100, 100, "USA"))
	add_country_to_level(Country.instance().init(75, 150, "Mexico"))
	add_country_to_level(Country.instance().init(120, 200, "Colombia"))
	add_country_to_level(Country.instance().init(190, 200, "Brazil"))
	add_country_to_level(Country.instance().init(170, 300, "Argentina"))
	
	add_connections("Alaska", ["West Canada"])
	add_connections("West Canada", ["Alaska", "East Canada", "USA"])
	add_connections("East Canada", ["West Canada", "USA"])
	add_connections("USA", ["East Canada", "West Canada", "Mexico", "Colombia"])
	add_connections("Mexico", ["USA", "Colombia"])
	add_connections("Colombia", ["Mexico", "Brazil", "Argentina", "USA"])
	add_connections("Brazil", ["Colombia", "Argentina"])
	add_connections("Argentina", ["Colombia", "Brazil"])

	for country in all_countries.values():
		add_child(country)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
