extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connections for level select
	var container = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/
	container.get_node("Crucible").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Crucible"])
	container.get_node("No Mans Land").connect("button_down", self, "_load_scene",  ["Levels/Level Main", "No Mans Land"])
	container.get_node("Our World").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Our World"])
	container.get_node("Random").connect("button_down", self, "_load_scene", ["Levels/Level Main", ""])
	
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.loaded_scene_history.pop_back()
	
	if _root.online_game == false:
		# Loading the previous scene
		var scene = _root.scene_manager._load_scene(prev_scene_str)
		_root.scene_manager._replace_scene(scene)

func brighten_sprite(sprite):
	sprite.modulate = Color(0.5,0.5,0.5)

func _load_scene(scene_str, world_str):
	# Remote Procedure Call if the game is online
	if _root.online_game:
		_root.rpc("load_level", scene_str, world_str)
	# Regular function call for offline game
	else:
		_root.load_level(scene_str, world_str)
