extends Control

onready var _root: Main = get_tree().get_root().get_node("Main")
# The connection can be "mandatory" or "at least one"
# At least one means that at least one of the childs parents must be true
var mode_connections = [\
	["Diffusion", "Fatigue", "mandatory"], ["Fatigue", "Raze", "at least one"],\
	["Resistance", "Raze", "at least one"], ["Drain", "Blitzkrieg", "mandatory"],\
	["Drain", "Congestion", "mandatory"], ["Deadline", "Congestion", "mandatory"]]

# Called when the node enters the scene tree for the first time.
func _ready(): 
	var container = $VBoxContainer
	container.get_node("HBoxContainer/Next/Button").connect("button_down", self, "_load_scene", ["UI/Level Select"])
	$TextureButton.connect("button_down", self, "back")
	# Button to go to help menu
	get_node("Help").connect("button_down", self, "show_help_menu")
	get_node("Load Save").connect("button_down", self, "load_save")
	container.get_node("HBoxContainer/Random").connect("button_down", self, "randomise_modes")
	
	# Connecting game mode dependencies
	container = $VBoxContainer/Control
	for mode_connection in mode_connections:
		var node1 = container.get_node(mode_connection[0])
		var node2 = container.get_node(mode_connection[1])
		var connnection_type = mode_connection[2]
		draw_connection(container, node1, node2, connnection_type)
	# Connecting up those dependencies, the dictionary is created for O(1) membership check
	var modes_with_dependencies = {}
	for mode_connection in mode_connections:
		modes_with_dependencies[mode_connection[0]] = true
		modes_with_dependencies[mode_connection[1]] = true
	for child in container.get_children():
		if child is CheckBox:
			child.connect("button_up", self, "collect_modes")
			if child.name in modes_with_dependencies:
				child.connect("button_up", self, "press_mode", [child.name])
	
	# Drawing the legend
	var label1 = $VBoxContainer/Control/Label
	var pos1 = label1.rect_position + Vector2(-10, label1.rect_size[1]/2)
	for child in (custom_draw_line(pos1, pos1 - Vector2(300, 0), true)):
		container.add_child(child)
	
	var label2 = $VBoxContainer/Control/Label2
	pos1 = label2.rect_position + Vector2(-10, label2.rect_size[1]/2)
	container.add_child(custom_draw_line(pos1, pos1 - Vector2(300, 0), false))

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
			children.append([mode_connection[1],mode_connection[2]])
	return children

func get_num_pressed_voluntary_modes(mode):
	var num = 0
	var container = $VBoxContainer/Control
	for mode_connection in mode_connections:
		if mode_connection[1] == mode and\
			mode_connection[2] == "at least one" and \
			container.get_node(mode_connection[0]).pressed:
			num += 1
	return num

func press_mode(mode):
	var container = $VBoxContainer/Control
	# Only execute if the button is being turned on by a user click
	if container.get_node(mode).pressed:
		sync_parent_dependencies(mode)
	# Only execute if the button is being turned off by a user click
	if not container.get_node(mode).pressed:
		sync_child_dependencies(mode)

func sync_parent_dependencies(mode):
	var container = $VBoxContainer/Control
	for parent_dependency in get_parent_dependencies(mode):
		sync_parent_dependencies(parent_dependency)
		container.get_node(parent_dependency).set_pressed(true)

func sync_child_dependencies(mode):
	var container = $VBoxContainer/Control
	for data in get_child_dependencies(mode):
		var child_dependency = data[0]
		var connection_type = data[1]
		if connection_type == "mandatory":
			container.get_node(child_dependency).set_pressed(false)
			sync_child_dependencies(child_dependency)
		else:
			# If none of the voluntary (at least one) modes are on, then turn off the child
			if get_num_pressed_voluntary_modes(child_dependency) == 0:
				container.get_node(child_dependency).set_pressed(false)
				sync_child_dependencies(child_dependency)

# Adding lines to show graph
func draw_connection(container, node1, node2, connection_type):
	var pos1 = (node1.rect_position + Vector2(node1.rect_size[0]/2/2, node1.rect_size[1]/2))
	var pos2 = (node2.rect_position + Vector2(node2.rect_size[0]/2/2, 0))
	
	# Move the end points away from the exact center of the mode labels.
	# This is to avoid connecting the lines and implying something
	var new_pos1 = pos1.linear_interpolate(pos2, 0.95)
	var new_pos2 = pos2.linear_interpolate(pos1, 0.95)
	
	match connection_type:
		"mandatory":
			container.add_child(custom_draw_line(new_pos1, new_pos2, false))
		"at least one":
			for line in custom_draw_line(new_pos1, new_pos2, true):
				container.add_child(line)

func custom_draw_line(pos1, pos2, bool_dashed):
	if not bool_dashed:
		var line = Line2D.new()
		line.add_point(pos1)
		line.add_point(pos2)
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.width = 5
		return line
	else:
		var lines = []
		for i in range(9):
			if i%2: continue
			var new_pos1 = pos1.linear_interpolate(pos2, float(i)/9)
			var new_pos2 = pos1.linear_interpolate(pos2, (float(i)/9) + (0.1))
			lines.append(custom_draw_line(new_pos1, new_pos2, false))
		return lines

func randomise_modes():
	randomize()
	var grid = get_node("VBoxContainer/Control")
	for child in grid.get_children():
		if child is CheckBox and child.name != "Classic":
			child.set_pressed(false)
	for child in grid.get_children():
		if child is CheckBox:
			var new_bool = bool(randi()%2)
			if new_bool:
				child.set_pressed(true)
				press_mode(child.name)
	collect_modes()

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager.save_and_hide_current_scene()
	_root.add_child(scene)

func back():
	# Removing the current scene from history
	_root.scene_manager.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.scene_manager.loaded_scene_history.pop_back()
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

func collect_modes():
	_root.game_modes = get_modes()

func get_modes():
	var container = $VBoxContainer/Control
	var game_modes = []
	for child in get_all_children(container):
		if child is CheckBox:
			if child.is_pressed():
				game_modes.append(child.name.to_lower())
	return game_modes

func _load_scene(scene_str):
	var scene = _root.scene_manager._load_scene(scene_str)
	_root.scene_manager._replace_scene(scene)

func load_save():
	var file = File.new()
	file.open("user://save_game.dat", File.READ)
	var content = parse_json(file.get_as_text())
	file.close()
	_root.load_save(content)
