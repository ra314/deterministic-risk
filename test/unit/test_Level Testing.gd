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
	_root.host()
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
	print("Giving the middle east 3 troops, and giving india and north africa 2 troops")
	
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

func test_movement1():
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

func test_movement2():
	init(["classic", "movement", "congestion"])
	
	print()
	print("Testing if the movement of troops work.")

	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")

	yield(get_tree().create_timer(1), "timeout")
	c_ME.change_ownership_to(main.curr_player)
	c_IND.change_ownership_to(main.curr_player)
	c_ME.set_initial_troops(5)
	c_IND.set_initial_troops(0)
	
	print("Checking that troops can't be moved from a country with 0 troops.")
	main.Phase.end_attack1(true)
	c_IND.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	yield(get_tree().create_timer(1), "timeout")
	assert_true(c_ME.num_reinforcements==0 and\
		no_lines_in(c_ME.get_children()) and\
		no_lines_in(c_IND.get_children()))
	
	print("Checking that troops can't be moved to a country that is already full")
	# Deselecting India
	c_IND.on_click(BUTTON_LEFT, false)
	c_IND.set_initial_troops(2)
	c_IND.set_num_troops(4)
	c_ME.on_click(BUTTON_LEFT, false)
	c_IND.on_click(BUTTON_LEFT, false)
	yield(get_tree().create_timer(1), "timeout")
	assert_true(c_IND.num_reinforcements==0 and\
		no_lines_in(c_ME.get_children()) and\
		no_lines_in(c_IND.get_children()))

func no_lines_in(arr):
	for node in arr:
		if node is Line2D:
			return false
	return true

func test_congestion():
	init(["classic", "congestion", "movement"])

	print()
	print("Testing the congestion game mode.")

	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")

	print("Checking that the max troops is 2 times the current")
	var num_errors = 0
	for country in main.all_countries.values():
		if country.num_troops * 2 != country.max_troops:
			num_errors += 1
	assert_true(num_errors == 0)
	
	print("Checking that the first and second player have the number of troops" +\
	"that were intended to be allocated to them.")
	var troops = []
	for country in main.curr_player.owned_countries:
		troops.append(country.num_troops)
	assert_true(troops.count(2)==2 and troops.count(3)==1)
	troops = []
	for country in main.get_next_player().owned_countries:
		troops.append(country.num_troops)
	assert_true(troops.count(1)==1 and troops.count(2)==2 and troops.count(3)==1)
	
	print("Checking that the max and current value of the progress bar match" +\
	"with max troops and num_troops + num_reinforcements.")
	num_errors = 0
	for country in main.all_countries.values():
		var progress_bar = country.Visual.get_node("Status/ProgressBar")
		if progress_bar.max_value != country.max_troops or\
		progress_bar.value != country.num_troops+country.num_reinforcements:
			num_errors += 1
	assert_true(num_errors == 0)
	
	print("Checking that attacking a country with more than it's max results in the extra troops being lost")
	c_IND.change_ownership_to(main.curr_player)
	c_IND.set_initial_troops(8)
	c_ME.change_ownership_to(main.get_next_player())
	c_ME.set_initial_troops(2)
	c_NA.change_ownership_to(main.curr_player)
	c_NA.set_initial_troops(5)
	yield(get_tree().create_timer(5), "timeout")
	
	# Giving IND extra troops, attacking ME and ensuring that troops don't overflow max
	c_IND.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	yield(get_tree().create_timer(1), "timeout")
	assert_true(c_IND.num_troops==1 and c_ME.num_troops == 4)
	
	print("Checking the movement doesn't allow the provision of troops beyond the max.")
	main.Phase.end_attack1(true)
	
	# Trying to move troops from NA to ME, while ME is already at max troops
	c_NA.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	yield(get_tree().create_timer(1), "timeout")
	assert_true(c_NA.num_troops==5 and\
		c_ME.num_reinforcements==0 and\
		no_lines_in(c_NA.get_children()) and\
		no_lines_in(c_ME.get_children()))
	
	print("Checking the extra reinforcements can't directly be provided that result in going beyond max")
	main.Phase.end_movement1()
	c_ME.on_click(BUTTON_LEFT, false)
	yield(get_tree().create_timer(1), "timeout")
	assert_true(c_ME.num_reinforcements==0)

func test_phases():
	init(["classic", "movement"])

	print()
	print("Testing the changing of phases")

	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	print("Checking the the current player has a sword above them and " +\
	"the next player has nothing above them.")
	assert_true("sword" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)
	
	print("Checking the the current player has a plane above them and " +\
	"the next player has nothing above them.")
	main.Phase.end_attack1(true)
	yield(get_tree().create_timer(1), "timeout")
	assert_true("plane" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)
	
	print("Checking the the current player has a shield above them and " +\
	"the next player has nothing above them.")
	main.Phase.end_movement1()
	yield(get_tree().create_timer(1), "timeout")
	assert_true("shield" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)
	
	print("Checking the the current player has a sword above them and " +\
	"the next player has nothing above them.")
	main.Phase.end_reinforcement1(true)
	yield(get_tree().create_timer(1), "timeout")
	assert_true("sword" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)
	
	print("Checking the the current player has a plane above them and " +\
	"the next player has nothing above them.")
	main.Phase.end_attack1(true)
	yield(get_tree().create_timer(1), "timeout")
	assert_true("plane" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)
	
	print("Checking the the current player has a shield above them and " +\
	"the next player has nothing above them.")
	main.Phase.end_movement1()
	yield(get_tree().create_timer(1), "timeout")
	assert_true("shield" in get_phase_symbol(main.curr_player).texture.load_path and\
	not get_phase_symbol(main.get_next_player()).visible)

func get_phase_symbol(player):
	return main.get_node("CanvasLayer/Game Info/" + player.color + "/VBoxContainer/Status")

func test_raze_and_resistance():
	init(["classic", "resistance","raze"])
	
	print()
	print("Testing if the resistance icon shows upon conquer and that the icon goes away upon being razed")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.set_num_troops(1)
	c_IND.set_num_troops(1)
	c_NA.set_num_troops(5)
	print("Give north africa 5 troops, and give the middle east and india 1 troop")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.change_ownership_to(main.get_next_player())
	c_IND.change_ownership_to(main.get_next_player())
	c_NA.change_ownership_to(main.curr_player)
	print("Giving north africa to the current player, and the middle east and india to the next player")
	
	yield(get_tree().create_timer(1), "timeout")
	c_NA.on_click(BUTTON_LEFT, false)
	c_ME.on_click(BUTTON_LEFT, false)
	print("Checking that ME has the resistance status and icon after being conquered")
	assert_true(c_ME.statused["resistance"] and\
		c_ME.get_node("Visual/Status/resistance").visible == true)
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.on_click(BUTTON_LEFT, false)
	main.get_node("CanvasLayer/Raze").emit_signal("button_down")
	print("Checking that ME is no longer in resistance after being razed and has 2 troops")
	assert_true(not c_ME.statused["resistance"] and\
		not c_ME.get_node("Visual/Status/resistance").visible and\
		c_ME.num_troops == 2)

func test_deadline():
	init(["classic", "deadline"])
	
	print()
	print("Testing if the game ends after 10 rounds in the deadline game mode.")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	for round_number in range(20):
		main.Phase.end_attack1(true)
		main.Phase.end_reinforcement1(true)
	
	assert_true(main.phase == "game over" and main.round_number == 21)

func test_end_attack_confirmation():
	init(["classic"])
	
	print()
	print("Testing if the end attack button doesn't show the confirmation prompt when no attacks are available.")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.set_num_troops(1)
	c_IND.set_num_troops(1)
	c_NA.set_num_troops(5)
	print("Give north africa 5 troops, and give the middle east and india 1 troop")
	
	yield(get_tree().create_timer(1), "timeout")
	c_ME.change_ownership_to(main.curr_player)
	c_IND.change_ownership_to(main.curr_player)
	c_NA.change_ownership_to(main.get_next_player())
	print("Giving north africa to the current player, and the middle east and india to the next player")
	
	assert_true(main.Phase.end_attack1(false))
	
func test_movement_no_action():
	init(["classic", "movement"])
	
	print()
	print("Testing if the movement phase skips to the reinforcement phase if the player can't make any movement actions")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	c_IND.set_num_troops(2)
	c_ME.set_num_troops(1)
	c_NA.set_num_troops(1)
	print("Give 2 troops to india, and give the north africa and middle east 1 troop")
	
	yield(get_tree().create_timer(1), "timeout")
	c_IND.change_ownership_to(main.get_next_player())
	c_ME.change_ownership_to(main.curr_player)
	c_NA.change_ownership_to(main.curr_player)
	print("Giving india to the next player, and middle east and north africa to the current plyer")
	
	print("Check if the current player cannot make a movement action")
	assert_false(main.Phase.start_movement1())
	
	main.Phase.end_reinforcement1(true)
	
	print("Check if the next player cannot make a movement action")
	assert_false(main.Phase.start_movement1())
