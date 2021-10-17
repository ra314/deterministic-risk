extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $CenterContainer/VBoxContainer
	container.get_node("Next/Button").connect("button_down", self, "_load_scene", ["UI/Level Select", get_modes()])
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

func get_modes():
	var container = $CenterContainer/VBoxContainer
	var game_modes = []
	for child in container.get_children():
		if child is CheckBox:
			if child.is_pressed():
				game_modes.append(child.name.to_lower())
	return game_modes

func _load_scene(scene_str, game_modes):
	_root.game_modes = game_modes
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
