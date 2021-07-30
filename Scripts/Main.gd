extends Node2D

class_name Main

var scene_manager: SceneManager = SceneManager.new(self)

func _ready():
	var scene = scene_manager._load_scene("UI/Local Online")
	scene_manager._replace_scene(scene)
