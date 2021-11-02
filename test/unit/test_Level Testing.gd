extends "res://addons/gut/test.gd"
var _root = load("res://Scenes/Main.tscn").instance()
var main = null
var func_retval = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_root)
	_root.visible = false
#	$C/Test1.connect("button_down", self, "test_long_press")
#	$C/Test2.connect("button_down", self, "test_blitz_and_drain")
	pass # Replace with function body.

func before_each():
#	$C.visible = false
	func_retval = false
	init(["classic", "drain", "blitzkrieg"])
	main = _root.get_children()[0]

func after_each():
#	$C.visible = true
	clean()

func after_all():
	main.free()

func init(game_modes = ["classic"]):
	_root.visible = true
	_root.host()
	_root.game_modes = game_modes
	_root.rpc("load_level", "Levels/Level Main", "Our World",  _root.game_modes)

func clean():
	_root.scene_manager._replace_scene(Node2D.new())

func test_blitz_and_drain():
	yield(t_blitz_and_drain(), "completed")
	assert_true(func_retval)

func t_blitz_and_drain():	
	print()
	print("Testing if the blitz icon shows up upon drain and that the icon goes away upon being conquered")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	main.all_countries["ff646464"].set_num_troops(3)
	main.all_countries["ff696969"].set_num_troops(2)
	main.all_countries["ff414141"].set_num_troops(2)
	print("Giving the middle east 3 troops, and giving india and north africa troops")
	
	yield(get_tree().create_timer(1), "timeout")
	main.all_countries["ff646464"].change_ownership_to(main.get_next_player())
	main.all_countries["ff696969"].change_ownership_to(main.curr_player)
	main.all_countries["ff414141"].change_ownership_to(main.curr_player)
	print("Giving the middle east to red, and giving india and north africa to blue")
	
	yield(get_tree().create_timer(1), "timeout")
	main.all_countries["ff696969"].on_click(BUTTON_LEFT, false)
	main.all_countries["ff646464"].on_click(BUTTON_LEFT, false)
	if main.all_countries["ff646464"].statused["blitzkrieg"] and\
		main.all_countries["ff646464"].get_node("Visual/Status/blitzkrieg").visible == true:
		print("Successfully drained the middle east")
	else:
		print("Failed to drain")
		func_retval = false
		return false
	
	yield(get_tree().create_timer(1), "timeout")
	main.all_countries["ff414141"].on_click(BUTTON_LEFT, false)
	main.all_countries["ff646464"].on_click(BUTTON_LEFT, false)
	if not main.all_countries["ff646464"].statused["blitzkrieg"] and\
		main.all_countries["ff646464"].get_node("Visual/Status/blitzkrieg").visible == false\
		and main.all_countries["ff646464"].belongs_to == main.player_neutral:
		print("Successfully blitz conquered the middle east")
	else:
		print("Failed to blitz conquer")
		func_retval = false
		return false
	
	print()
	yield(get_tree().create_timer(1), "timeout")
	func_retval = true
	return true

func test_long_press():
	yield(t_long_press(), "completed")
	assert_true(func_retval)

func t_long_press():
	print()
	print("Testing if a long press removes all reinforcements")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	main.Phase.end_attack1(true)
	print("Ending attack")
	
	yield(get_tree().create_timer(1), "timeout")
	var available_reinforcements = main.curr_player.num_reinforcements
	print(str(available_reinforcements) + " reinforcements are available.")
	# Iteratively add all available reinforcements
	for i in range(main.curr_player.num_reinforcements):
		main.curr_player.owned_countries[0].on_click(BUTTON_LEFT, false)
	if main.curr_player.owned_countries[0].num_reinforcements == available_reinforcements:
		print("Successfully added all available reinforcement")
	else:
		print("Failed to add all available reinforcement")
		func_retval = false
		return false
	
	yield(get_tree().create_timer(1), "timeout")
	main.curr_player.owned_countries[0].on_click(BUTTON_LEFT, true)
	if main.curr_player.owned_countries[0].num_reinforcements == 0:
		print("Successfully removed all reinforcements")
	else:
		print("Failed to remove all reinforcements")
		func_retval = false
		return false
	
	print()
	yield(get_tree().create_timer(1), "timeout")
	func_retval = true
	return true


