extends "res://Scripts/Level_Funcs.gd"

#onready var _root: Main = get_tree().get_root().get_node("Main")
var _root = null

var input_allowed = true
var input_pressed = false
var time_pressed = 0
var game_modes = []

var colors = {"blue": load("res://Assets/blue-square.svg"), 
				"red": load("res://Assets/red-pentagon.svg"),
				"gray": load("res://Assets/neutral-circle.svg")}

var game_over = false
var selected_country = null
var phase = "attack"
var curr_level = self

var round_number = 1
const max_rounds = 10

var round_number_label = null

var curr_player = null
var curr_player_index = null
const num_players = 2
# Dictionary mapping player names ("red", "blue") to player objects
var players = null
var game_started = false

func load_world():
	# Loading existing level
	if .import_level(self, true):
		print("imported")
	# Load the default half complete earth level
	else:
		.create_default_level(self)

# Clear the player dictionary, rerandomise troop allocation and redo player turn order and country allocation
func reset_spawn():
	for player in players.values():
		if player.color == "gray": continue
		player.reset()
	curr_player = null
	for country in all_countries.values():
		country.change_ownership_to(players["gray"])
		country.randomise_troops()

func spawn_and_allocate():
	# Creating players
	players = {"red": get_node("CanvasLayer/Player Red").init("red"), "blue": get_node("CanvasLayer/Player Blue").init("blue")}
	# Adding the neutral player
	players["gray"] = player_neutral
	
	reset_spawn()

	# Randomizing players
	randomize()
	curr_player_index = randi() % num_players
	curr_player = players.values()[curr_player_index]
	
	# Randomly allocating countries
	add_random_countries(get_next_player(), 4)
	add_random_countries(curr_player, 3)
	
	# Assigning the owned countries with a predetermined spread:
	var troops_to_assign = [2,2,3]
	for country in curr_player.owned_countries:
		country.set_num_troops(select_random(troops_to_assign))
		troops_to_assign.erase(country.num_troops)
	
	troops_to_assign = [2,3,1,2]
	for country in get_next_player().owned_countries:
		country.set_num_troops(select_random(troops_to_assign))
		troops_to_assign.erase(country.num_troops)
	
	# Checking if all player owned countries have a country they can attack
	for player in players.values().slice(0,1):
		for country in player.owned_countries:
			if country.num_troops > 1:
				if len(country.get_attackable_countries(["classic"])) == 0:
					print("BAD spawn, I have " + str(country.num_troops) + " units and am " + country.belongs_to.color)
					return false
	
	# Check that all player owned countries cannot immediately attack another player owned country
	for player in players.values().slice(0,1):
		for attacker in player.owned_countries:
			for defender in attacker.get_attackable_countries(["classic"]):
				if defender.belongs_to.color != "gray":
					print("BAD spawn, I have " + str(defender.num_troops) + " units and am " + defender.belongs_to.color + " and can be attacked")
					return false
	
#	print("The first player is " + curr_player.color)
#	print(curr_player.color)
	update_labels()
	$Phase.update_player_status(curr_player.color, true)
	print("Found good spawn")
	return true
	
# Called when the node enters the scene tree for the first time.
func _ready():
	load_world()
	
	while not spawn_and_allocate():
		pass
	
	# Buttons to zoom in and out
	get_node("CanvasLayer/Zoom In").connect("pressed", get_node("Camera2D"), "zoom_in")
	get_node("CanvasLayer/Zoom Out").connect("pressed", get_node("Camera2D"), "zoom_out")
	
	# Button to end attack and reinforcement phases
	get_node("CanvasLayer/End Attack").connect("pressed", $Phase, "change_to_reinforcement1")
	get_node("CanvasLayer/End Reinforcement").connect("pressed", $Phase, "change_to_attack1")
	
	# Buttons to select if host plays as red or blue
	get_node("CanvasLayer/Init Buttons/Online/Play Red").connect("button_down", self, "set_host_color", ["red"])
	get_node("CanvasLayer/Init Buttons/Online/Play Blue").connect("button_down", self, "set_host_color", ["blue"])
	# Don't let the guest choose who goes first
	if not _root.online_game or _root.player_name == "guest":
		get_node("CanvasLayer/Init Buttons/Online").queue_free()
	
	# Button to reroll the troop allocation to the countries
	get_node("CanvasLayer/Init Buttons/Reroll Spawn").connect("button_down", self, "reroll_spawn")
	# Don't let the guest reroll the spawn.
	if _root.online_game and _root.player_name == "guest":
		get_node("CanvasLayer/Init Buttons").queue_free()
	
	# Button to start the game, when clicked it removes itself and the reroll button
	if _root.online_game:
		get_node("CanvasLayer/Init Buttons/Start Game").queue_free()
	else:
		get_node("CanvasLayer/Init Buttons/Start Game").connect("button_down", self, "remove_reroll_and_start_butttons")
		
	# Button to go to help menu
	get_node("CanvasLayer/Help").connect("button_down", self, "show_help_menu")
	
	# Button to resign game
	get_node("CanvasLayer/Resign").connect("button_down", self, "show_confirmation_menu", ["Are you sure you want to resign?", "resign", [], self])
	get_node("CanvasLayer/Restart").connect("button_down", self, "restart")
	
	# Confirmation buttons
	# Hiden the confirmation menu when either yes or no is clicked
	get_node("CanvasLayer/Confirm/VBoxContainer/CenterContainer/HBoxContainer/No").\
		connect("button_down", get_node("CanvasLayer/Confirm"), "set_visible", [false])
	get_node("CanvasLayer/Confirm/VBoxContainer/CenterContainer/HBoxContainer/Yes").\
		connect("button_down", get_node("CanvasLayer/Confirm"), "set_visible", [false])
	
	# Button to toggle visibility of denominator in congestion mode
	if "congestion" in game_modes:
		get_node("CanvasLayer/Show").connect("button_down", self, "toggle_denominator_visibility")
		get_node("CanvasLayer/Show").visible = true
		toggle_denominator_visibility()
	
	# If you're the guest _root.game_modes is empty since the host picks them out
	# However load_level() in main syncs up the game mdoe with the level main scene
	# So we're just pushing these game modes back to the root
	# This is necessary so that the asterisks show up next to the selected game modes on the help screen
	_root.game_modes = game_modes
	print(game_modes)

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager.save_and_hide_current_scene()
	_root.add_child(scene)

var show_denominator = true
func toggle_denominator_visibility():
	show_denominator = not show_denominator
	for country in all_countries.values():
		country.get_node("Visual").show_congestion_denominator(show_denominator)

# Confirmation System
#######
var prev_signal = {"object":null, "method":null}
func show_confirmation_menu(confirmation_text, callback, args, object):
	get_node("CanvasLayer/Confirm/VBoxContainer/Label").text = confirmation_text
	get_node("CanvasLayer/Confirm").visible = true
	# Disablign previously connected signal if ther was a previous signal connection
	if prev_signal["object"]:
		$CanvasLayer/Confirm/VBoxContainer/CenterContainer/HBoxContainer/Yes.\
			disconnect("button_down", prev_signal["object"], prev_signal["method"])
		prev_signal = {"object":null, "method":null}
	if object:
		$CanvasLayer/Confirm/VBoxContainer/CenterContainer/HBoxContainer/Yes.\
			connect("button_down", object, callback, args)
		prev_signal = {"object":object, "method":callback}
#######

# Button Removal and Hiding Functions
#######
# This relies on an assumption that this funciton is only called in offline games
func remove_reroll_and_start_butttons():
	show_end_attack(true)
	show_resign_button()
	game_start_event()

remotesync func show_resign_button():
	get_node("CanvasLayer/Resign").visible = true

remote func show_end_attack(show_boolean):
	# Do nothing if checkers is one of the game modes since the end attack button is hidden by default
	if not ("checkers" in game_modes):
		get_node("CanvasLayer/End Attack").visible = show_boolean

func show_end_reinforcement(show_boolean):
	get_node("CanvasLayer/End Reinforcement").visible = show_boolean
#######

# AI
#######
# We duplicate the existing countries so that modifications here do not propogate outside
func clone_country(country):
	var new_country = Country.init(country.x, country.y, country.country_name, country.player)
	new_country.set_num_troops(country.num_troops)
	return new_country

func extract_game_state():
	var game_state = {}
	for player in players.values():
		game_state[player.color] = {}
		for country in player.owner_countries:
			game_state[player.color][country.country_name] = clone_country(country)
	return game_state

func get_child_states(game_state, curr_player_color):
	for country in game_state[curr_player_color]:
		for attackable_country in country.get_attackable_countries():
			pass

# The depth parameter is not how deep the function is currently, 
# but how much deeper it should go
# minimax(extract_game_state(), 3, -INF, INF, true) 
func minimax(game_state, depth, alpha, beta, maximizing_player):
	pass
######
func reroll_spawn():
	while not spawn_and_allocate():
		pass
	if _root.online_game:
		$Sync.synchronize(_root.players["guest"])

# Because we mod by the number of players, it doesn't matter that there' an extra player_neutral
func get_next_player():
	return players.values()[(curr_player_index+1)%num_players]

func get_player_by_network_id(network_id):
	for player in players.values():
		if player.network_id == network_id:
			return player
	return null

# Called when the game starts (after color selection) regardless of online or offline
func game_start_event():
	game_started = true
	get_node("CanvasLayer/Init Buttons").queue_free()
	if "checkers" in game_modes:
		get_node("CanvasLayer/End Attack").visible = false

# This relies on an assumption that this funciton is only called in online games
func set_host_color(color):
	# Assigning network ids to the players
	players[color].network_id = _root.players["host"]
	var other_color = "blue"
	if color == "blue":
		other_color = "red"
	players[other_color].network_id = _root.players["guest"]
	
	game_start_event()
	$Sync.synchronize(_root.players["guest"])
	
	# Changing the visibility of relevant buttons
	rpc("show_resign_button")
	
	if curr_player.network_id == _root.players[_root.player_name]:
		print("changing local button")
		show_end_attack(true)
	else:
		print("changing other guyss button")
		rpc_id(curr_player.network_id, "show_end_attack", true)

# Checks if a country is non adjacent to a player
func is_country_neighbour_of_player(test_country, player):
	for country in player.owned_countries:
		if test_country in country.connected_countries:
			return true
	return false

func add_random_countries(player, num_countries):
	# Checking that sufficient number of countries are available	
	if curr_level.get_num_neutral_countries() < num_countries:
		print("not enough countries")
		get_tree().quit()
	
	# Adding random countries to the player
	var num_added_countries = 0
	var loop_counter = 0
	while num_added_countries < num_countries:
		loop_counter += 1
		var country = select_random(curr_level.all_countries.values())
		if loop_counter > 1000:
			print("Not enough countries for all starting countries to be non adjacent.\n1000 iterations completed.")
			get_tree().quit()
		
		# Ensuring that the country is not adjacent to the opponent and is unowned
		if country.belongs_to.color == "gray" and not is_country_neighbour_of_player(country, get_next_player()):
			country.change_ownership_to(player)
			num_added_countries += 1
	update_labels()
	
func is_attack_over():
	for country in curr_player.owned_countries:
		if country.get_attackable_countries(game_modes):
			return false
	return true

# Ending the game
#######
func resign():
	if _root.online_game:
		var loser_color = get_player_by_network_id(_root.players[_root.player_name]).color
		rpc("end_game", loser_color)
	else:
		rpc("end_game", curr_player.color)

remotesync func end_game(loser_color):
	# Hiding buttons to prevent further gameplay and allowing game restart
	get_node("CanvasLayer/End Attack").visible = false
	get_node("CanvasLayer/End Reinforcement").visible = false
	get_node("CanvasLayer/Resign").visible = false
	get_node("CanvasLayer/Restart").visible = true
	phase = "game over"
	stop_flashing()
	
	# Finding out who the winner is
	var players_without_loser = players.keys()
	players_without_loser.erase(loser_color)
	var winner_color = players_without_loser[0]
	
	# Win screen
	var game_info = get_node("CanvasLayer/Game Info")
	
	# Placing a crown above the icon of the winner
	var winner_icon = game_info.get_node(winner_color + "/VBoxContainer/Status")
	winner_icon.visible = true
	winner_icon.texture = load("res://Assets/Icons/Win.svg")
	
	# Placing a skull above the icon of the loser
	var loser_icon = game_info.get_node(loser_color + "/VBoxContainer/Status")
	loser_icon.visible = true
	loser_icon.texture = load("res://Assets/Icons/Lose.svg")

func restart():
	back()

func back():
	# Removing the current scene from history
	_root.loaded_scene_history.pop_back()
	# Removing the previous scene from history since we're going to load it again
	var prev_scene_str = _root.loaded_scene_history.pop_back()
	# Reverting side effects
	# There were none
	# Loading the previous scene
	var scene = _root.scene_manager._load_scene(prev_scene_str)
	_root.scene_manager._replace_scene(scene)
#######

func update_labels():
	# Update Red labels
	var red = get_node("CanvasLayer/Game Info/red/VBoxContainer2/HBoxContainer")
	red.get_node("Reinforcements").text = str(players["red"].num_reinforcements) + "/" + str(players["red"].get_num_reinforcements())
	red.get_node("Units").text = str(players["red"].get_num_troops())
	red.get_node("Countries").text = str(len(players["red"].owned_countries))
	
	# Update Blue labels
	var blue = get_node("CanvasLayer/Game Info/blue/VBoxContainer2/HBoxContainer")
	blue.get_node("Reinforcements").text = str(players["blue"].num_reinforcements) + "/" + str(players["blue"].get_num_reinforcements())
	blue.get_node("Units").text = str(players["blue"].get_num_troops())
	blue.get_node("Countries").text = str(len(players["blue"].owned_countries))
	
	# Update Round info
	get_node("CanvasLayer/Game Info/Round Info/HBoxContainer/Round").text = "Round: " + str(round_number)
	var curr_texture = colors["gray"]
	if curr_player:
		curr_texture = colors[curr_player.color]
	get_node("CanvasLayer/Game Info/Round Info/HBoxContainer/Curr Player").texture = curr_texture

# Used to translate a random click on the map, to translate to a click on a country
func _input(event):
	if (event is InputEventMouseButton) or (event is InputEventScreenTouch):
		if (not _root.online_game) or is_current_player():
			if event.pressed and input_allowed:
				input_allowed = false
				input_pressed = true
			
			if not event.pressed:
				var is_long_press = time_pressed > 0.5
				input_pressed = false
				time_pressed = 0
				var map_click_position = (event.position*$Camera2D.zoom) + $Camera2D.position
				rpc("click_country", map_click_position, event.button_index, is_long_press)

remotesync func click_country(map_click_position, event_index, is_long_press):
	# Check if the click is actually inside the map
	if not (Rect2(Vector2(0,0), world_mask.get_size()).has_point(map_click_position)):
		return
	
	# Since it's possible for the click to be in something like the ocean,
	# We verify that the color returned is actually assigned to a country
	var country_name = str(get_color_in_mask(map_click_position))
	if country_name in all_countries:
		all_countries[country_name].on_click(event_index, is_long_press)

func stop_flashing():
	for country in all_countries.values():
		country.get_node("Visual").stop_flashing()

func is_current_player():
	if len(_root.players) == 0:
		return true
	else:
		return _root.players[_root.player_name] == curr_player.network_id

const sync_period = 2
var time_since_sync = 0
const input_frequency = 0.05
var time_since_last_input = 0

func _process(delta):
	# Measuring time input is held down
	if input_pressed:
		time_pressed += delta
	
	# Preventing mouse input repeats
	time_since_last_input += delta
	if time_since_last_input > input_frequency:
		input_allowed = true
		time_since_last_input = 0
