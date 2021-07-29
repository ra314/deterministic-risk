extends "res://Scripts/Level_Funcs.gd"

func stop_flashing():
	for country in all_countries.values():
		country.stop_flashing()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_size(Vector2(1920, 1080))
	
	# Loading existing level
	if .import_level(self):
		print("imported")
	# Load the default half complete earth level
	else:
		.create_default_level(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
