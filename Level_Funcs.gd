var Country = load("res://Country.tscn")

func export_level(all_countries):
	var save_game = File.new()
	save_game.open("res://savegame.save", File.WRITE)
	for country in all_countries.values():
		save_game.store_line(to_json(country.save()))
	save_game.close()

func import_level(level_node):	
	# Instantiating countries
	var save_game = File.new()
	save_game.open("res://savegame.save", File.READ)
	var all_countries = {}
	
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		var new_country = Country.instance().init(node_data["x"], node_data["y"], node_data["name"])
		add_country_to_level(all_countries, new_country)
		level_node.add_child(new_country)
	
	# Adding connections
	save_game.open("res://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		for country_name in node_data["connections"]:
			all_countries[node_data["name"]].add_connection(all_countries[country_name])
		
	level_node.all_countries = all_countries

func draw_lines_between_countries(all_countries):
	for country in all_countries.values():
		for neighbour in country.connected_countries:
			country.draw_line_to_country(neighbour)

func add_country_to_level(all_countries, country):
	all_countries[country.country_name] = country

func add_connections(all_countries, source_country_name, destination_country_names):
	for destination_country_name in destination_country_names:
		all_countries[source_country_name].add_connection(all_countries[destination_country_name])
