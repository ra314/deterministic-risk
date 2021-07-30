tool
extends HBoxContainer

class_name MenuItem

#onready var _root: Main = get_tree().get_root().get_node("Root")

export var item_name: String = "ITEM" setget _set_item_name

func _ready():
	# warning-ignore:return_value_discarded
	$Button.connect("mouse_entered", self, "_add_text_highlight")
	# warning-ignore:return_value_discarded
	$Button.connect("mouse_exited", self, "_remove_text_highlight")

func _remove_text_highlight():
	$SelectedBefore.visible = false
	$SelectedAfter.visible = false
	
func _add_text_highlight():
	$SelectedBefore.visible = true
	$SelectedAfter.visible = true

func _set_item_name(name: String):
	item_name = name
	$Button.text = item_name
