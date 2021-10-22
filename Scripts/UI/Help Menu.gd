extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Return To Game").connect("button_down", self, "_load_scene")
	for child in $"VBoxContainer/Menu Options".get_children():
		child.connect("button_down", self, "show_item", [child.name, $"VBoxContainer/Menu Display"])
	for child in $"VBoxContainer/Menu Display/Game Modes/Game Modes".get_children():
		child.connect("button_down", self, "show_item", [child.name, $"VBoxContainer/Menu Display/Game Modes/Control"])

func show_item(item_name, container):
	for child in container.get_children():
		child.visible = (child.name == item_name)

func _load_scene():
	_root.scene_manager.load_saved_scene()
