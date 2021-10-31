extends VBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	$Local/Button.connect("button_down", self, "_load_scene", ["UI/Mode Select"])
	$Online/Button.connect("button_down", self, "_load_scene",  ["UI/Host Guest"])
	
	$Local/Button.connect("button_down", _root, "host")
	$Online/Button.connect("button_down", self, "set_online")

func set_online():
	_root.online_game = true

func _load_scene(scene_str):	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
