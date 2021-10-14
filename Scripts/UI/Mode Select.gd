extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $CenterContainer/VBoxContainer
	container.get_node("Classic/Button").connect("button_down", self, "_load_scene", ["UI/Level Select", "classic"])
	container.get_node("Drain/Button").connect("button_down", self, "_load_scene",  ["UI/Level Select", "drain"])
	container.get_node("Checkers/Button").connect("button_down", self, "_load_scene",  ["UI/Level Select", "checkers"])
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.loaded_scene_history.pop_back()
	# Reverting side effects
	if _root.online_game:
		_root.player_name = ""
		_root.players = {}
		_root.peer.close_connection()
		_root.get_tree().network_peer = null
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

func _load_scene(scene_str, game_mode):
	_root.game_mode = game_mode
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
