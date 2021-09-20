extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $CenterContainer/VBoxContainer
	container.get_node("Host/Button").connect("button_down", self, "_load_scene", ["UI/Level Select"])
	container.get_node("Guest/Button").connect("button_down", self, "_load_scene",  ["UI/IP Select"])
	
	$TextureButton.connect("button_down", self, "back")

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
	# Dirty workaround to check if the pressed button was host
	if scene_str == "UI/Level Select":
		_root.player_name = "host"
		_root.host()
	# Dirty workaround to check if the pressed button was guest
	if scene_str == "UI/IP Select":
		_root.player_name = "guest"
	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
