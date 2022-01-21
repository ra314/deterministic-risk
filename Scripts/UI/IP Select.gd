extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")

# Called when the node enters the scene tree for the first time.
func _ready():
	var container = $CenterContainer/VBoxContainer
	container.get_node("Connect/Button").connect("button_down", self, "_load_scene", ["UI/Waiting"])
	$CenterContainer/VBoxContainer/HBoxContainer/TextEdit.connect("text_changed", self, "check_for_newline")
	# Loading the previously used IP address
	if _root.stored_IP:
		$CenterContainer/VBoxContainer/HBoxContainer/TextEdit.text = _root.stored_IP
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
	var server_IP = $CenterContainer/VBoxContainer/HBoxContainer/TextEdit.text.strip_edges(true, true)
	_root.guest(server_IP)
	_root.stored_IP = server_IP
	
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)

func check_for_newline():
	var textedit = $CenterContainer/VBoxContainer/HBoxContainer/TextEdit
	if not textedit:
		return
	if textedit.text[textedit.text.length()-1] == '\n':
		$CenterContainer/VBoxContainer/Connect/Button.emit_signal("button_down")
