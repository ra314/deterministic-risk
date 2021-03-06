extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Return To Game").connect("button_down", self, "_load_scene")
	# Connect the menu buttons to show their menu's
	for child in $"VBoxContainer/Menu Options".get_children():
		child.connect("button_down", self, "show_item", [child.name, $"VBoxContainer/Menu Display"])
	
	# Connect the game mode buttons to display rules about the selected game mode
	for child in $"VBoxContainer/Menu Display/Game Modes/ScrollContainer/Game Modes".get_children():
		child.connect("button_down", self, "show_item", [child.name, $"VBoxContainer/Menu Display/Game Modes/Control"])
	$"VBoxContainer/Menu Display/Game Modes/ScrollContainer".get_v_scrollbar().rect_min_size.x = 50

func show_item(item_name, container):
	for child in container.get_children():
		child.visible = (child.name == item_name)
		if item_name == "Game Modes" and child.name == "Game Modes":
			for game_mode in $"VBoxContainer/Menu Display/Game Modes/ScrollContainer/Game Modes".get_children():
				# "if _root" is for better unit testing
				if _root and game_mode.name.to_lower() in _root.game_modes:
					game_mode.text = "*" + game_mode.name
					game_mode.add_color_override("font_color", Color(0,0.5,0))
					game_mode.add_color_override("font_color_hover", Color(0,1,0))
	
	# Toggle the other menu option buttons off
	if container.name == "Menu Display":
		for child in $"VBoxContainer/Menu Options".get_children():
			if child.name != item_name:
				child.set_pressed(false)

func _load_scene():
	_root.scene_manager.load_saved_scene()

func load_save():
	_load_scene()
	var file = File.new()
	file.open("user://save_game.dat", File.READ)
	var content = parse_json(file.get_as_text())
	file.close()
	_root.load_save(content)
