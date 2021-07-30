extends HBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	get_node("Crucible").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Crucible"])
	get_node("No Mans Land").connect("button_down", self, "_load_scene",  ["Levels/Level Main", "No Mans Land"])
	get_node("Our World").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Our World"])
	get_node("Random").connect("button_down", self, "_load_scene", ["Levels/Level Main", ""])

func _load_scene(scene_str, world_str):
	var scene = _root.scene_manager._load_scene(scene_str)
	scene.load_world(world_str)
	_root.scene_manager._replace_scene(scene)
