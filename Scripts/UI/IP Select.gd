extends VBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	$Connect/Button.connect("button_down", self, "_load_scene", ["UI/Waiting"])

func _load_scene(scene_str):
	# Slicing out the IP address
	var server_IP = get_node("HBoxContainer/TextEdit").text
	_root.guest(server_IP)
	print(server_IP)
	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
