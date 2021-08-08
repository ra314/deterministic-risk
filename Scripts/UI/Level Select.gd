extends HBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connections for level select
	get_node("Crucible").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Crucible"])
	get_node("No Mans Land").connect("button_down", self, "_load_scene",  ["Levels/Level Main", "No Mans Land"])
	get_node("Our World").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Our World"])
	get_node("Random").connect("button_down", self, "_load_scene", ["Levels/Level Main", ""])
	
	# Connections for brightening sprites
#	get_node("Crucible").connect("mouse_entered", self, "brighten_sprite", ["Crucible"])
#	get_node("No Mans Land").connect("mouse_entered", self, "brighten_sprite", ["No Mans Land"])
#	get_node("Our World").connect("mouse_entered", self, "brighten_sprite", ["Our World"])
	
	# Connections for darkening sprites

func brighten_sprite(sprite):
	sprite.modulate = Color(0.5,0.5,0.5)

func _load_scene(scene_str, world_str):
	if _root.online_game:
		_root.rpc("load_level", scene_str, world_str)
	else:
		_root.load_level(scene_str, world_str)
