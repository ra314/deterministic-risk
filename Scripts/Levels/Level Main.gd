extends "res://Scripts/Level_Funcs.gd"

onready var _root: Main = get_tree().get_root().get_node("Main")
const sync_period = 2
var time_since_sync = 0

func stop_flashing():
	for country in all_countries.values():
		country.stop_flashing()
	
var game_over = false
var selected_country = null
var phase = "attack"
var curr_level = self

# Maintains the number of reinforcements a country receives during the reinforcement phase
# Ensures that more reinforcements can't be removed than are added from any country
var reinforced_countries = {}

var round_number = 1
const max_rounds = 10

var round_number_label = null

var curr_player = null
var curr_player_index = null
const num_players = 2
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
	
	# Button to end attack
	get_node("CanvasLayer/End Attack").connect("pressed", self, "change_to_reinforcement")
	
	# Button to end reinforcement
	get_node("CanvasLayer/End Reinforcement").connect("pressed", self, "change_to_attack")
	
	# Buttons to select if host plays as red or blue
	get_node("CanvasLayer/Play Red").connect("button_down", self, "set_host_color", ["red"])
	get_node("CanvasLayer/Play Blue").connect("button_down", self, "set_host_color", ["blue"])
	# Don't let the guest choose who goes first
	if not _root.online_game or _root.player_name == "guest":
		remove_color_select_buttons()
	
	# Button to reroll the troop allocation to the countries
	get_node("CanvasLayer/Reroll Spawn").connect("button_down", self, "reroll_spawn")
	# Don't let the guest reroll the spawn.
	if _root.online_game and _root.player_name == "guest":
		remove_reroll_spawn_button()
	
	# Button to start the game, when clicked it removes itself and the reroll button
	if _root.online_game:
		get_node("CanvasLayer/Start Game").queue_free()
	else:
		get_node("CanvasLayer/Start Game").connect("button_down", self, "remove_reroll_and_start_butttons")
		
	# Button to go to help menu
	get_node("CanvasLayer/Help").connect("button_down", self, "show_help_menu")

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager.save_and_hide_current_scene()
	_root.add_child(scene)

# Button Removal and Hiding Functions
#######
# This relies on an assumption that this funciton is only called in offline games
func remove_reroll_and_start_butttons():
	remove_reroll_spawn_button()
	get_node("CanvasLayer/Start Game").queue_free()
	change_view_of_end_attack(false)
	game_started = true

remotesync func remove_reroll_spawn_button():
	get_node("CanvasLayer/Reroll Spawn").queue_free()

remotesync func remove_color_select_buttons():
	get_node("CanvasLayer/Play Red").queue_free()
	get_node("CanvasLayer/Play Blue").queue_free()

remote func change_view_of_end_attack(hide_boolean):
	if hide_boolean:
		get_node("CanvasLayer/End Attack").hide()
	else:
		get_node("CanvasLayer/End Attack").show()

remote func change_view_of_end_reinforcement(hide_boolean):
	if hide_boolean:
		get_node("CanvasLayer/End Reinforcement").hide()
	else:
		get_node("CanvasLayer/End Reinforcement").show()
#######

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

# This relies on an assumption that this funciton is only called in online games
func set_host_color(color):
	# Assigning network ids to the players
	players[color].network_id = _root.players["host"]
	var other_color = "blue"
	if color == "blue":
		other_color = "red"
	players[other_color].network_id = _root.players["guest"]
	synchronize(_root.players["guest"])
	
	# Changing the visibility of relevant buttons
	remove_color_select_buttons()
	remove_reroll_spawn_button()
	
	if curr_player.network_id == _root.players[_root.player_name]:
		print("changing local button")
		change_view_of_end_attack(false)
	else:
		print("changing other guyss button")
		rpc_id(curr_player.network_id, "change_view_of_end_attack", false)
	
	game_started = true

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
		print(country.belongs_to)
		if country.belongs_to.color == "gray" and not is_country_neighbour_of_player(country, get_next_player()):
			country.change_ownership_to(player)
			num_added_countries += 1
	player.update_labels()
	
func is_attack_over():
	for country in curr_player.owned_countries:
		if country.can_attack():
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
	change_view_of_end_attack(true)
	change_view_of_end_reinforcement(false)
	
	phase = "reinforcement"

func change_to_attack():
	# Modifying the visibility of the end attack and end reinforcement buttons	
	if _root.online_game:
		change_view_of_end_reinforcement(true)
		rpc_id(get_next_player().network_id, "change_view_of_end_attack", false)
	else:
		change_view_of_end_attack(false)
		change_view_of_end_reinforcement(true)
	
	# Cleaning up the dictionary that was tracking where reinforcements were placed
	reinforced_countries.clear()
	
	selected_country = null
	change_to_next_player()
	round_number += 1
	update_labels()
	phase = "attack"
#######

func get_player_with_most_troops():
	var player_with_most_troops = null
	var max_num_troops = 0
	for player in players.values():
		if player.get_num_troops() > max_num_troops:
			player_with_most_troops = player
			max_num_troops = player.get_num_troops()
	return player_with_most_troops

func end_game():
	get_node("CanvasLayer/End Attack").visible = false
	get_node("CanvasLayer/End Reinforcement").visible = false
	phase = "game over"
	get_node("CanvasLayer/Player and Round Tracker").text = get_player_with_most_troops().color + " Wins"

func update_labels():
	get_node("CanvasLayer/Player and Round Tracker").text = "Current Player: " + curr_player.color + "\nRound: " + str(round_number)

func _input(event):	
	if event.is_pressed():
		if not (Rect2(Vector2(0,0), world_mask.get_size()).has_point(get_local_mouse_position())):
			return

		# Print color of pixel under mouse cursos when clicked
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
		rpc_id(network_id, "synchronise_country", country.country_name, country.num_troops, country.belongs_to.color)
	
	# Synchrosing the game in terms of player information
	for player in players.values():
		rpc_id(network_id, "synchronise_player", player.save())
	
	# Synchronising meta information
	rpc_id(network_id, "synchronise_meta_info", curr_player_index, round_number, game_started)

remote func synchronise_country(country_name, num_troops, color):
	all_countries[country_name].synchronise(num_troops, players[color])

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
#######

func _process(delta):
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
