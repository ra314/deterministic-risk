extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
var mode_connections = [["Diffusion", "Fatigue"], ["Fatigue", "Raze"],\
	["Resistance", "Raze"], ["Drain", "Blitzkrieg"], ["Drain", "Congestion"], ["Deadline", "Congestion"]]
#	["Classic", "Movement"], ["Movement", "Pandemic"], ["Pandemic", "Checkers"]]

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $VBoxContainer
	container.get_node("HBoxContainer/Next/Button").connect("button_down", self, "_load_scene", ["UI/Level Select"])
	$TextureButton.connect("button_down", self, "back")
	# Button to go to help menu
	get_node("Help").connect("button_down", self, "show_help_menu")
	container.get_node("HBoxContainer/Random").connect("button_down", self, "randomise_modes")
	
	# Connecting game mode dependencies
	container = $VBoxContainer/Control
	for mode_connection in mode_connections:
		var node1 = container.get_node(mode_connection[0])
		var node2 = container.get_node(mode_connection[1])
		draw_connection(container, node1, node2)
	# Connecting up those dependencies
	var modes_with_dependencies = {}
	for mode_connection in mode_connections:
		modes_with_dependencies[mode_connection[0]] = true
		modes_with_dependencies[mode_connection[1]] = true
	for child in container.get_children():
		if child is CheckBox and child.name in modes_with_dependencies:
			child.connect("button_down", self, "press_mode", [child.name])

func get_parent_dependencies(mode):
	var parents = []
	for mode_connection in mode_connections:
		if mode_connection[1] == mode:
			parents.append(mode_connection[0])
	return parents

func get_child_dependencies(mode):
	var children = []
	for mode_connection in mode_connections:
		if mode_connection[0] == mode:
			children.append(mode_connection[1])
	return children

func get_num_pressed_modes(modes):
	var num = 0
	var container = $VBoxContainer/Control
	for mode in modes:
		num += int(container.get_node(mode).pressed)
	return num

func press_mode(mode):
	var container = $VBoxContainer/Control
	# Only execute if the button is being turned on by a user click
	if not container.get_node(mode).pressed:
		sync_parent_dependencies(mode)
	# Only execute if the button is being turned off by a user click
	if container.get_node(mode).pressed:
		sync_child_dependencies(mode)

func sync_parent_dependencies(mode):
	var container = $VBoxContainer/Control
	for parent_dependency in get_parent_dependencies(mode):
		sync_parent_dependencies(parent_dependency)
		container.get_node(parent_dependency).set_pressed(true)

func sync_child_dependencies(mode):
	var container = $VBoxContainer/Control
	for child_dependency in get_child_dependencies(mode):
		if get_num_pressed_modes(get_parent_dependencies(child_dependency)) == 1:
			sync_child_dependencies(child_dependency)
			container.get_node(child_dependency).set_pressed(false)

# Adding lines to show graph
func draw_connection(container, node1, node2):
	# Connect Diffusion and fatigue
	var line = Line2D.new()
	line.add_point(node1.rect_position + Vector2(node1.rect_size[0]/2/2, node1.rect_size[1]/2))
	line.add_point(node2.rect_position + Vector2(node2.rect_size[0]/2/2, 0))
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	container.add_child(line)

func randomise_modes():
	randomize()
	var grid = get_node("VBoxContainer/Control")
	for child in grid.get_children():
		if child is CheckBox:
			child.set_pressed(false)
	for child in grid.get_children():
		if child is CheckBox:
			var new_bool = bool(randi()%2)
			if new_bool != child.pressed:
				child.emit_signal("button_down")
				child.set_pressed(new_bool)

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager.save_and_hide_current_scene()
	_root.add_child(scene)

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

func get_all_children(object):
	var output = []
	for child in object.get_children():
		output.append(child)
		output.append_array(get_all_children(child))
	return output
	
func get_modes():
	var container = $VBoxContainer/Control
	var game_modes = []
	for child in get_all_children(container):
		if child is CheckBox:
			if child.is_pressed():
				game_modes.append(child.name.to_lower())
	return game_modes

func _load_scene(scene_str):
	_root.game_modes = get_modes()
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)
