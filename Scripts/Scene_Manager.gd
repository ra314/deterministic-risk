extends Node2D

class_name SceneManager

var _root: Node2D

func _init(root: Node2D):
	_root = root

func _load_scene(name: String):
	var container = _root.get_children()[0]
	_remove_children(container)
	var scene: String = 'res://Scenes/' + name + '.tscn' 
	container.replace_by(load(scene).instance())

func _remove_children(node: Node):
	for child in node.get_children():
		child.queue_free()
