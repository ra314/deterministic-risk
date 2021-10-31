extends Node2D
var _root = load("res://Scenes/Main.tscn").instance()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_root)
	_root.visible = false
	$C/Test1.connect("button_down", self, "run_test", ["test_long_press"])
	pass # Replace with function body.

func init():
	_root.visible = true
	_root.host()
	_root.game_modes = ["classic"]
	_root.rpc("load_level", "Levels/Level Main", "Our World",  _root.game_modes)

func clean():
	_root.scene_manager._replace_scene(Node2D.new())

func run_test(test_name):
	$C.visible = false
	init()
	
	yield(call(test_name), "completed")
	
	clean()
	$C.visible = true

func test_long_press():
	print()
	print("Testing if a long press removes all reinforcements")
	
	yield(get_tree().create_timer(1), "timeout")
	_root.get_children()[0].remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	_root.get_children()[0].get_node("Phase").change_to_reinforcement1(true)
	print("Ending attack")
	
	yield(get_tree().create_timer(1), "timeout")
	var available_reinforcements = _root.get_children()[0].curr_player.num_reinforcements
	print(str(available_reinforcements) + " reinforcements are available.")
	# Iteratively add all available reinforcements
	for i in range(_root.get_children()[0].curr_player.num_reinforcements):
		_root.get_children()[0].curr_player.owned_countries[0].on_click(BUTTON_LEFT, false)
	if _root.get_children()[0].curr_player.owned_countries[0].num_reinforcements == available_reinforcements:
		print("Successfully added all available reinforcement")
	else:
		print("Failed to add all available reinforcement")
		return false
	
	yield(get_tree().create_timer(1), "timeout")
	_root.get_children()[0].curr_player.owned_countries[0].on_click(BUTTON_LEFT, true)
	if _root.get_children()[0].curr_player.owned_countries[0].num_reinforcements == 0:
		print("Successfully removed all reinforcements")
	else:
		print("Failed to remove all reinforcements")
		return false
	
	print()
	yield(get_tree().create_timer(2), "timeout")
	return true


