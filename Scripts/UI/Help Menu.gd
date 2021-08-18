extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Return To Game").connect("button_down", self, "_load_scene")
	pass # Replace with function body.

func _load_scene():
	_root.scene_manager.load_saved_scene()
