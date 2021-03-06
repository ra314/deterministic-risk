extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connections for level select
	var container = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/
	container.get_node("Southern Seas").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Southern Seas"])
	container.get_node("No Mans Land").connect("button_down", self, "_load_scene",  ["Levels/Level Main", "No Mans Land"])
	container.get_node("Our World").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Our World"])
	container = $CenterContainer/VBoxContainer/CenterContainer4/HBoxContainer/
	container.get_node("Isle of the Fyre").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Isle of the Fyre"])
	container.get_node("Novingrad").connect("button_down", self, "_load_scene", ["Levels/Level Main", "Novingrad"])
	container.get_node("Random").connect("button_down", self, "_load_scene", ["Levels/Level Main", ""])
	
	$TextureButton.connect("button_down", self, "back")

func back():
	# Removing the current scene from history
	_root.scene_manager.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.scene_manager.loaded_scene_history.pop_back()
	# Reverting side effects
	_root.game_modes = ["classic"]
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)

func brighten_sprite(sprite):
	sprite.modulate = Color(0.5,0.5,0.5)

func select_random(array):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return array[rng.randi() % len(array)]

func _load_scene(scene_str, world_str):
	var worlds = ["Southern Seas", "Our World", "No Mans Land", "Isle of the Fyre", "Novingrad"]

	# Pick the random world if the world_str is empty
	if world_str == "":
		world_str = select_random(worlds)
	
	_root.rpc("load_level", scene_str, world_str,  _root.game_modes)
