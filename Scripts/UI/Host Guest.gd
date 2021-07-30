extends VBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	$Host/Button.connect("button_down", self, "_load_scene", ["UI/Level Select"])
	$Guest/Button.connect("button_down", self, "_load_scene",  ["UI/Waiting"])

func _load_scene(scene_str):
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
