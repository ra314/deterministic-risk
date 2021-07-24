extends Node2D

var Country = load("res://Country.tscn")
var all_countries = {}

func get_num_neutral_countries():
	var count = 0
	for country in all_countries.values():
		count += int(country.belongs_to == null)
	return count

func create_default_level(level_node):	
	# Instantiating countries
	add_country_to_level(Country.instance().init(50, 50, "Alaska"))
	add_country_to_level(Country.instance().init(100, 50, "West Canada"))
	add_country_to_level(Country.instance().init(150, 70, "East Canada"))
	add_country_to_level(Country.instance().init(100, 100, "USA"))
	add_country_to_level(Country.instance().init(75, 150, "Mexico"))
	add_country_to_level(Country.instance().init(120, 200, "Colombia"))
	add_country_to_level(Country.instance().init(190, 200, "Brazil"))
	add_country_to_level(Country.instance().init(170, 300, "Argentina"))
	
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

func export_level():
	var save_game = File.new()
	save_game.open("res://savegame.save", File.WRITE)
	# Converting each country to a json and dumping them all
	for country in all_countries.values():
		save_game.store_line(to_json(country.save()))
	save_game.close()

func import_level(level_node):	
	# Instantiating countries
	var save_game = File.new()
	save_game.open("res://savegame.save", File.READ)
	
	# Going through the json save
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		var new_country = Country.instance().init(node_data["x"], node_data["y"], node_data["name"])
		add_country_to_level(new_country)
		level_node.add_child(new_country)
	
	# Adding connections
	save_game.open("res://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		add_connections(node_data["name"], node_data["connections"])

# A line to visualize adjacent countries in the level creator
func draw_lines_between_countries():
	for country in all_countries.values():
		for neighbour in country.connected_countries:
			country.draw_line_to_country(neighbour)

func add_country_to_level(country):
	all_countries[country.country_name] = country

func add_connections(source_country_name, destination_country_names):
	for destination_country_name in destination_country_names:
		all_countries[source_country_name].add_connection(all_countries[destination_country_name])
