extends "res://addons/gut/test.gd"
var _root = load("res://Scenes/Main.tscn").instance()
var main = null
var c_IND = null
var c_NA = null
var c_ME = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_root)
	_root.visible = false
#	$C/Test1.connect("button_down", self, "test_long_press")
#	$C/Test2.connect("button_down", self, "test_blitz_and_drain")
	pass # Replace with function body.

func after_each():
#	$C.visible = true
	clean()

func after_all():
	if main:
		main.free()

func init(game_modes = ["classic"]):
	_root.visible = true
	_root.host()
	_root.game_modes = game_modes
	_root.rpc("load_level", "Levels/Level Main", "Our World",  _root.game_modes)
	
	main = _root.get_children()[0]
	c_ME = main.all_countries["ff646464"]
	c_IND = main.all_countries["ff696969"]
	c_NA = main.all_countries["ff414141"]

func clean():
	_root.scene_manager._replace_scene(Node2D.new())

func test_blitz_and_drain():
	init(["classic", "drain", "blitzkrieg"])
	
	print()
	print("Testing if the blitz icon shows up upon drain and that the icon goes away upon being conquered")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.set_num_troops(3)
	c_IND.set_num_troops(2)
	c_NA.set_num_troops(2)
	print("Giving the middle east 3 troops, and giving india and north africa troops")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.change_ownership_to(main.get_next_player())
	c_IND.change_ownership_to(main.curr_player)
	c_NA.change_ownership_to(main.curr_player)
	print("Giving the middle east to next player, and giving india and north africa to the current player")
	
	yield(get_tree().create_timer(1), "timeout")
	c_IND.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	print("Checking that ME has the blitz status and icon after being drained")
	assert_true(c_ME.statused["blitzkrieg"] and\
		c_ME.get_node("Visual/Status/blitzkrieg").visible == true)
	
	yield(get_tree().create_timer(1), "timeout")
	c_NA.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	print("Checking that ME is neutral, and no longer has blitz icon or status after being conquered")
	assert_true(not c_ME.statused["blitzkrieg"] and\
		not c_ME.get_node("Visual/Status/blitzkrieg").visible and\
		c_ME.belongs_to == main.player_neutral)

func test_long_press():
	init(["classic"])
	
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
	print("Checking if all available reinforcements were added")
	assert_true(main.curr_player.owned_countries[0].num_reinforcements == available_reinforcements)

	yield(get_tree().create_timer(1), "timeout")
	main.curr_player.owned_countries[0].on_click(BUTTON_LEFT, true)
	print("Checking is all reinforcements were remvoed after a long press")
	assert_true(main.curr_player.owned_countries[0].num_reinforcements == 0)

func test_movement():
	init(["classic", "movement"])
	
	print()
	print("Testing if the movement of troops work.")

	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")

	yield(get_tree().create_timer(1), "timeout")
	c_ME.set_num_troops(5)
	c_IND.set_num_troops(1)
	c_NA.set_num_troops(1)
	print("Giving the middle east 5 troops, and giving india and north africa 1 troop")

	yield(get_tree().create_timer(1), "timeout")
	c_ME.change_ownership_to(main.curr_player)
	c_IND.change_ownership_to(main.curr_player)
	c_NA.change_ownership_to(main.curr_player)
	print("Giving the middle east, india and north africa to the current player.")

	yield(get_tree().create_timer(1), "timeout")
	main.Phase.end_attack1(true)
	print("Ending attack")

	yield(get_tree().create_timer(1), "timeout")
	c_ME.on_click(BUTTON_LEFT, false)
	c_IND.on_click(BUTTON_LEFT, false)
	c_IND.on_click(BUTTON_LEFT, false)
	c_NA.on_click(BUTTON_LEFT, false)
	c_NA.on_click(BUTTON_LEFT, false)
	print("Move 2 troops each from ME to IND and NA.")

	print("Checking that IND and NA have 2 reinforcements, while ME has 1 troop.")
	assert_true(c_ME.num_troops == 1 and\
		c_IND.num_reinforcements == 2 and\
		c_NA.num_reinforcements == 2)

	print("Checking that there are lines from ME to IND and NA")
	assert_true(c_IND in c_ME.Visual.lines and c_NA in c_ME.Visual.lines)

	yield(get_tree().create_timer(1), "timeout")
	c_ME.on_click(BUTTON_LEFT, true)
	print("Resetting movement")

	print("Checking resetting donations works as intended.")
	assert_true(c_ME.num_troops == 5 and\
		c_IND.num_reinforcements == 0 and\
		c_NA.num_reinforcements == 0)

	yield(get_tree().create_timer(1), "timeout")
	c_IND.on_click(BUTTON_LEFT, false)
	c_IND.on_click(BUTTON_LEFT, false)
	c_NA.on_click(BUTTON_LEFT, false)
	c_NA.on_click(BUTTON_LEFT, false)
	print("Move 2 troops each from ME to IND and NA.")

	print("Checking that IND and NA have 2 reinforcements, while ME has 1 troop.")
	assert_true(c_ME.num_troops == 1 and\
		c_IND.num_reinforcements == 2 and\
		c_NA.num_reinforcements == 2)

	yield(get_tree().create_timer(1), "timeout")
	main.Phase.end_movement1()
	print("Ending movement")

	print("Checking that the troops have moved to the right place")
	assert_true(c_ME.num_troops == 1 and\
		c_IND.num_reinforcements == 0 and c_IND.num_troops == 3 and\
		c_NA.num_reinforcements == 0 and c_NA.num_troops == 3)

	print("Checking that the lines are gone")
	assert_true(no_lines_in(c_ME.get_children()) and\
		no_lines_in(c_IND.get_children()) and\
		no_lines_in(c_NA.get_children()))

func no_lines_in(arr):
	for node in arr:
		if node is Line2D:
			return false
	return true
