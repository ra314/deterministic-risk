extends VBoxContainer

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready(): 
	$Host/Button.connect("button_down", self, "_load_scene", ["UI/Level Select"])
	$Guest/Button.connect("button_down", self, "_load_scene",  ["UI/IP Select"])

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
