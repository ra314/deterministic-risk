extends Node2D
var _root = load("res://Scenes/Main.tscn").instance()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_root)
	_root.visible = false
	$C/Test1.connect("button_down", self, "test_long_press")
	$C/Test2.connect("button_down", self, "test_blitz_and_drain")
	pass # Replace with function body.

func init(game_modes = ["classic"]):
	_root.visible = true
	_root.host()
	_root.game_modes = game_modes
	_root.rpc("load_level", "Levels/Level Main", "Our World",  _root.game_modes)

func clean():
	_root.scene_manager._replace_scene(Node2D.new())

func test_blitz_and_drain():
	$C.visible = false
	init(["classic", "drain", "blitzkrieg"])
	var main = _root.get_children()[0]
	
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
		return false
	
	print()
	yield(get_tree().create_timer(1), "timeout")
	
	clean()
	$C.visible = true
	return true


func test_long_press():
	$C.visible = false
	init()
	var main = _root.get_children()[0]
	
	print()
	print("Testing if a long press removes all reinforcements")
	
	yield(get_tree().create_timer(1), "timeout")
	main.remove_reroll_and_start_butttons()
	print("Starting game")
	
	yield(get_tree().create_timer(1), "timeout")
	main.get_node("Phase").change_to_reinforcement1(true)
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
		return false
	
	yield(get_tree().create_timer(1), "timeout")
	main.curr_player.owned_countries[0].on_click(BUTTON_LEFT, true)
	if main.curr_player.owned_countries[0].num_reinforcements == 0:
		print("Successfully removed all reinforcements")
	else:
		print("Failed to remove all reinforcements")
		return false
	
	print()
	yield(get_tree().create_timer(1), "timeout")
	
	clean()
	$C.visible = true
	return true


