extends "res://Scripts/Level_Funcs.gd"

onready var _root: Main = get_tree().get_root().get_node("Main")

var input_allowed = true

func stop_flashing():
	for country in all_countries.values():
		country.stop_flashing()
	
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

func init(world_str):
	load_world(world_str)
	return self

func load_world(world_str):
	# Loading existing level
	if .import_level(self, world_str):
		print("imported")
	# Load the default half complete earth level
	else:
		.create_default_level(self)

func spawn_and_allocate():
	# Creating players
	players = {"red": get_node("CanvasLayer/Player Red").init("red"), "blue": get_node("CanvasLayer/Player Blue").init("blue")}
	# Adding the neutral player
	players["gray"] = player_neutral

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
		country.num_troops = select_random(troops_to_assign)
		troops_to_assign.erase(country.num_troops)
		country.update_labels()
	
	troops_to_assign = [2,3,1,2]
	for country in get_next_player().owned_countries:
		country.num_troops = select_random(troops_to_assign)
		troops_to_assign.erase(country.num_troops)
		country.update_labels()
	
	print("The first player is " + curr_player.color)
	update_labels()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_and_allocate()
	
	# Button to toggle showing player and round info
	get_node("CanvasLayer/Toggle Info").connect("pressed", self, "toggle_info_visibility")
	
	# Buttons to zoom in and out
	get_node("CanvasLayer/Zoom In").connect("pressed", get_node("Camera2D"), "zoom_in")
	get_node("CanvasLayer/Zoom Out").connect("pressed", get_node("Camera2D"), "zoom_out")
	
	# Button to end attack
	get_node("CanvasLayer/End Attack").connect("pressed", self, "change_to_reinforcement")
	
	# Button to end reinforcement
	get_node("CanvasLayer/End Reinforcement").connect("pressed", self, "change_to_attack")
	
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
	get_node("CanvasLayer/Resign").connect("button_down", self, "show_resignation_menu")
	get_node("CanvasLayer/Confirm Resign/VBoxContainer/CenterContainer/HBoxContainer/No").connect("button_down", self, "confirm_resign", [false])
	get_node("CanvasLayer/Confirm Resign/VBoxContainer/CenterContainer/HBoxContainer/Yes").connect("button_down", self, "confirm_resign", [true])

func show_resignation_menu():
	get_node("CanvasLayer/Confirm Resign").visible = true

func confirm_resign(confirmation_bool):
	if confirmation_bool:
		resign()
	get_node("CanvasLayer/Confirm Resign").visible = false

func resign():
	if _root.online_game:
		end_game(get_player_by_network_id(_root.players[_root.player_name]).color)
	else:
		end_game(curr_player.color)

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager.save_and_hide_current_scene()
	_root.add_child(scene)

func toggle_info_visibility():
	get_node("CanvasLayer/Player and Round Tracker").visible = !get_node("CanvasLayer/Player and Round Tracker").visible
	for player in players.values():
		player.get_node("Label").visible = !player.get_node("Label").visible

# Button Removal and Hiding Functions
#######
# This relies on an assumption that this funciton is only called in offline games
func remove_reroll_and_start_butttons():
	get_node("CanvasLayer/Init Buttons").queue_free()
	end_attack_disable(false)
	show_resign_button()
	game_started = true

remotesync func show_resign_button():
	get_node("CanvasLayer/Resign").visible = true

remote func end_attack_disable(hide_boolean):
	print("End attack buttons is being " + str(hide_boolean))
	if hide_boolean:
		get_node("CanvasLayer/End Attack").hide()
	else:
		get_node("CanvasLayer/End Attack").show()

func end_reinforcement_disable(hide_boolean):
	print("End reinforcement buttons is being " + str(hide_boolean))
	if hide_boolean:
		get_node("CanvasLayer/End Reinforcement").hide()
	else:
		get_node("CanvasLayer/End Reinforcement").show()
#######

# AI
#######
# We duplicate the existing countries so that modifications here do not propogate outside
func clone_country(country):
	var new_country = Country.init(country.x, country.y, country.country_name, country.player)
	new_country.num_troops = country.num_troops
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

# Clear the player dictionary, rerandomise troop allocation and redo player turn order and country allocation
func reroll_spawn():
	for player in players.values():
		if player.color == "gray": continue
		player.reset()
	for country in all_countries.values():
		country.change_ownership_to(players["gray"])
		country.randomise_troops()
	spawn_and_allocate()

# Because we mod by the number of players, it doesn't matter that there' an extra player_neutral
func get_next_player():
	return players.values()[(curr_player_index+1)%num_players]

func get_player_by_network_id(network_id):
	for player in players.values():
		if player.network_id == network_id:
			return player
	return null

# This relies on an assumption that this funciton is only called in online games
func set_host_color(color):
	# Assigning network ids to the players
	players[color].network_id = _root.players["host"]
	var other_color = "blue"
	if color == "blue":
		other_color = "red"
	players[other_color].network_id = _root.players["guest"]
	game_started = true
	synchronize(_root.players["guest"])
	
	# Changing the visibility of relevant buttons
	get_node("CanvasLayer/Init Buttons").queue_free()
	rpc("show_resign_button")
	
	if curr_player.network_id == _root.players[_root.player_name]:
		print("changing local button")
		end_attack_disable(false)
	else:
		print("changing other guyss button")
		rpc_id(curr_player.network_id, "end_attack_disable", false)

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
	player.update_labels()
	
func is_attack_over():
	for country in curr_player.owned_countries:
		if country.get_attackable_countries():
			return false
	return true

# Changing phases of the game
#######
func change_to_next_player():
	curr_player_index = (curr_player_index+1)%num_players
	curr_player = players.values()[curr_player_index]
	# We're synchronizing the current player because after the change 
	# the current player is no longer the instance this function was called on
	if _root.online_game:
		synchronize(curr_player.network_id)

func change_to_reinforcement():	
	selected_country = null
	curr_level.stop_flashing()
	curr_player.give_reinforcements()
	
	# Modifying the visibility of the end attack and end reinforcement buttons
	end_attack_disable(true)
	end_reinforcement_disable(false)
	
	phase = "reinforcement"

func change_to_attack():
	# Modifying the visibility of the end attack and end reinforcement buttons	
	if _root.online_game:
		end_reinforcement_disable(true)
		rpc_id(get_next_player().network_id, "end_attack_disable", false)
	else:
		end_attack_disable(false)
		end_reinforcement_disable(true)
	
	# Moving the troops from reinforcement to actual unit
	for country in all_countries.values():
		country.num_troops += country.num_reinforcements
		country.num_reinforcements = 0
		country.update_labels()
	
	selected_country = null
	round_number += 1
	change_to_next_player()
	update_labels()
	phase = "attack"
#######

remote func end_game(loser_color):
	# Hiding buttons to prevent further gameplay
	get_node("CanvasLayer/End Attack").visible = false
	get_node("CanvasLayer/End Reinforcement").visible = false
	get_node("CanvasLayer/Resign").visible = false
	phase = "game over"
	
	# Making win screen visible
	get_node("CanvasLayer/Win Screen").visible = true
	# Adding the loser and winners name in the right places
	get_node("CanvasLayer/Win Screen/Loser").text = loser_color
	# Finding out who the winne is
	var players_without_loser = players.keys()
	players_without_loser.erase(loser_color)
	var winner_color = players_without_loser[0]
	get_node("CanvasLayer/Win Screen/Winner").text = winner_color
	
	# Online component
	if _root.online_game:
		rpc_id(players[winner_color].network_id , "end_game", loser_color)

func update_labels():
	get_node("CanvasLayer/Player and Round Tracker").text = "Current Player: " +\
		curr_player.color + "\nRound: " + str(round_number)

func _input(event):	
	if event.is_pressed() and input_allowed:
		input_allowed = false
		if not (Rect2(Vector2(0,0), world_mask.get_size()).has_point(get_local_mouse_position())):
			return

		# Print color of pixel under mouse cursor when clicked
		print(get_color_in_mask())

		var country_name = get_color_in_mask()[0]
		if country_name in all_countries:
			all_countries[country_name].on_click(event)

# Network synchronisation
#######
func synchronize(network_id):
	print("syncing")
	
	# Synchronising the countries in terms of colors and troops
	for country in all_countries.values():
		rpc_id(network_id, "synchronise_country", country.country_name, \
			country.num_troops, country.num_reinforcements, country.belongs_to.color)
	
	# Synchrosing the game in terms of player information
	for player in players.values():
		rpc_id(network_id, "synchronise_player", player.save())
	
	# Synchronising meta information
	rpc_id(network_id, "synchronise_meta_info", curr_player_index, round_number, game_started)

remote func synchronise_country(country_name, num_troops, num_reinforcements, color):
	all_countries[country_name].synchronise(num_troops, num_reinforcements, players[color])

remote func synchronise_player(player_info):
	var curr_player = players[player_info["color"]]
	curr_player.network_id = player_info["network_id"]
	curr_player.num_reinforcements = player_info["num_reinforcements"]
	curr_player.update_labels()

remote func synchronise_meta_info(_curr_player_index, _round_number, _game_started):
	game_started = _game_started
	round_number = _round_number
	curr_player_index = _curr_player_index
	curr_player = players.values()[curr_player_index]
	update_labels()

# Below functions are for the movement of countries during the attack phase to propagate across network
func move_country_across_network(origin_country_name, destination_country_name):
	rpc_id(get_next_player().network_id, "move_to_country", origin_country_name, destination_country_name)
	synchronize(get_next_player().network_id)

remote func move_to_country(origin_country_name, destination_country_name):
	all_countries[origin_country_name].move_to_country(all_countries[destination_country_name])
#######

const sync_period = 2
var time_since_sync = 0
const input_frequency = 0.05
var time_since_last_input = 0

func _process(delta):
	# Preventing mouse input repeats
	time_since_last_input += delta
	if time_since_last_input > input_frequency:
		input_allowed = true
		time_since_last_input = 0
	
	# Skip synchronisation if not online
	if not _root.online_game:
		return
	
	if game_started:
		# Skip synchronisation if this instance of the game isn't the current player and the host color has been set
		if _root.players[_root.player_name] != curr_player.network_id:
			return
	else:
		# Skip synchronisation if this instance of the game is not the host and the host color hasn't been set
		if _root.player_name != "host":
			return
	
	time_since_sync += delta
	if time_since_sync > sync_period:
		if game_started:
			synchronize(get_next_player().network_id)
		else:
			synchronize(_root.players["guest"])
		time_since_sync = 0
