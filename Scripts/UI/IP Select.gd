extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	var container = $CenterContainer/VBoxContainer
	container.get_node("Connect/Button").connect("button_down", self, "_load_scene", ["UI/Waiting"])
	
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.loaded_scene_history.pop_back()
	# Reverting side effects
	_root.player_name = ""
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

func _load_scene(scene_str):
	# Slicing out the IP address
	var server_IP = $CenterContainer/VBoxContainer/HBoxContainer/TextEdit.text
	_root.guest(server_IP)
	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
