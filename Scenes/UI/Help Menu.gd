extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Return To Game").connect("button_down", self, "_load_scene", ["UI/Level Select"])
	pass # Replace with function body.

func _load_scene(scene_str):	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
