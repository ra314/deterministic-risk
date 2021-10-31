extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $CenterContainer/VBoxContainer
	container.get_node("Host/Button").connect("button_down", self, "_load_scene", ["UI/Mode Select"])
	container.get_node("Guest/Button").connect("button_down", self, "_load_scene",  ["UI/IP Select"])
	
	$TextureButton.connect("button_down", self, "back")
	
	container.get_node("Host/Button").connect("button_down", self, "set_player_name", ["host"])
	container.get_node("Guest/Button").connect("button_down", self, "set_player_name", ["guest"])

func set_player_name(player_name):
	_root.player_name = player_name
	if player_name == "host":
		_root.host()

func back():
	# Removing the current scene from history
	_root.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.loaded_scene_history.pop_back()
	# Reverting side effects
	_root.online_game = false
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

func _load_scene(scene_str):
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
