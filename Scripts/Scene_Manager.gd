extends Node2D

class_name SceneManager

var _root: Node2D
var loaded_scene_history = []

func _init(root: Node2D):
	_root = root

func _load_scene(name: String):
	var scene: String = 'res://Scenes/' + name + '.tscn' 
	if name != "UI/Help Menu":
		loaded_scene_history.append(name)
	return load(scene).instance()

func _get_curr_scene():
	return _root.get_children()[0]

func _replace_scene(scene):
	var container = _get_curr_scene()
	_remove_children(container)
	container.replace_by(scene)

func _remove_children(node: Node):
	for child in node.get_children():
		child.queue_free()

var saved_scene = null

func save_and_hide_current_scene():
	_root.get_children()[0].visible = false
	_root.get_children()[0].get_node("CL/C").visible = false

func load_saved_scene():
	_root.remove_child(_root.get_children()[1])
	_root.get_children()[0].visible = true
	_root.get_children()[0].get_node("CL/C").visible = true

func reset():
	loaded_scene_history = []
	saved_scene = null
