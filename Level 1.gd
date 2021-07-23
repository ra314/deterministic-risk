extends Node
var Country = load("res://Country.tscn")
var all_countries = {}

# Importing Level Functions
var Level_Funcs = load("Level_Funcs.gd") # Relative path
onready var LF = Level_Funcs.new()
	
func stop_flashing():
	for country in all_countries.values():
		country.stop_flashing()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_size(Vector2(1920, 1080))
	
	#Loading existing level
	var save_game = File.new()
	if save_game.file_exists("res://savegame.save"):
		LF.import_level(self)
	return
	
	# America
	LF.add_country_to_level(all_countries, Country.instance().init(50, 50, "Alaska"))
	LF.add_country_to_level(all_countries, Country.instance().init(100, 50, "West Canada"))
	LF.add_country_to_level(all_countries, Country.instance().init(150, 70, "East Canada"))
	LF.add_country_to_level(all_countries, Country.instance().init(100, 100, "USA"))
	LF.add_country_to_level(all_countries, Country.instance().init(75, 150, "Mexico"))
	LF.add_country_to_level(all_countries, Country.instance().init(120, 200, "Colombia"))
	LF.add_country_to_level(all_countries, Country.instance().init(190, 200, "Brazil"))
	LF.add_country_to_level(all_countries, Country.instance().init(170, 300, "Argentina"))
	
	LF.add_connections(all_countries, "Alaska", ["West Canada"])
	LF.add_connections(all_countries, "West Canada", ["Alaska", "East Canada", "USA"])
	LF.add_connections(all_countries, "East Canada", ["West Canada", "USA"])
	LF.add_connections(all_countries, "USA", ["East Canada", "West Canada", "Mexico", "Colombia"])
	LF.add_connections(all_countries, "Mexico", ["USA", "Colombia"])
	LF.add_connections(all_countries, "Colombia", ["Mexico", "Brazil", "Argentina", "USA"])
	LF.add_connections(all_countries, "Brazil", ["Colombia", "Argentina"])
	LF.add_connections(all_countries, "Argentina", ["Colombia", "Brazil"])

	for country in all_countries.values():
		add_child(country)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
