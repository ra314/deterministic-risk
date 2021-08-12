extends "res://Scripts/Level_Funcs.gd"

onready var _root: Main = get_tree().get_root().get_node("Main")
const sync_period = 2

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
var Player = load("res://Scenes/Levels/Level Components/Player.tscn")
var players = null

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
	if not _root.online_game:
		remove_color_select_buttons()
	
	# Button to reroll the troop allocation to the countries
	get_node("CanvasLayer/Reroll Spawn").connect("button_down", self, "reroll_spawn")
	if _root.online_game:
		get_node("CanvasLayer/Start Game").queue_free()
	else:
		get_node("CanvasLayer/Start Game").connect("button_down", self, "hide_reroll_and_start_butttons")
		
	# Button to go to help menu
	get_node("CanvasLayer/Help").connect("button_down", self, "show_help_menu")

func show_help_menu():
	var scene = _root.scene_manager._load_scene("UI/Help Menu")
	_root.scene_manager._replace_scene(scene)

func hide_reroll_and_start_butttons():
	remove_reroll_spawn_button()
	get_node("CanvasLayer/Start Game").queue_free()

# Clear the player dictionary, rerandomise troop allocation and redo player turn order and country allocation
func reroll_spawn():
	for player in players.values():
		player.reset()
	for country in all_countries.values():
		country.change_ownership_to(null)
		country.randomise_troops()
	spawn_and_allocate()

func get_next_player():
	return players.values()[(curr_player_index+1)%num_players]

func change_to_next_player():
	if _root.online_game:
		# Wait 1 extra second to ensure syncronisation
		yield(get_tree().create_timer(sync_period+1), "timeout")
		curr_player_index = (curr_player_index+1)%num_players
		curr_player = players.values()[curr_player_index]
		
		var player_info = []
		for player in players.values():
			player_info.append(player.save())
		rpc_id(curr_player.network_id, "synchronise_players_and_round", curr_player_index, round_number, player_info)
	else:
		curr_player_index = (curr_player_index+1)%num_players
		curr_player = players.values()[curr_player_index]

func set_host_color(color):
	# Assigning network ids to the players
	players[color].network_id = _root.players["host"]
	var other_color = "blue"
	if color == "blue":
		other_color = "red"
	players[other_color].network_id = _root.players["guest"]
	rpc("remove_color_select_buttons")
	rpc("remove_reroll_spawn_button")
	
	# Synching network id info to the guest
	var player_info = []
	for player in players.values():
		player_info.append(player.save())
	rpc_id(players[other_color].network_id, "synchronise_players_and_round", curr_player_index, round_number, player_info)

remotesync func remove_reroll_spawn_button():
	get_node("CanvasLayer/Reroll Spawn").queue_free()

# Hiding the buttons
remotesync func remove_color_select_buttons():
	get_node("CanvasLayer/Play Red").queue_free()
	get_node("CanvasLayer/Play Blue").queue_free()

func select_random(array):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return array[rng.randi() % len(array)]

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
		if country.belongs_to == null and not is_country_neighbour_of_player(country, get_next_player()):
			country.change_ownership_to(player)
			num_added_countries += 1
	player.update_labels()
	
func is_attack_over():
	for country in curr_player.owned_countries:
		if country.can_attack():
			return false
	return true

func change_to_reinforcement():	
	selected_country = null
	curr_level.stop_flashing()
	curr_player.give_reinforcements()
	
	get_node("CanvasLayer/End Attack").visible = false
	get_node("CanvasLayer/End Reinforcement").visible = true
	phase = "reinforcement"

func change_to_attack():
	# Round limit
#	if round_number == 10:
#		end_game()
#		return
	
	# Cleaning up the dictionary that was tracking where reinforcements were placed
	reinforced_countries.clear()
	
	change_to_next_player()
	round_number += 1
	update_labels()
	
	get_node("CanvasLayer/End Attack").visible = true
	get_node("CanvasLayer/End Reinforcement").visible = false
	phase = "attack"

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

# Network synchronisation
remote func synchronise_country(country_name, num_troops, color):
	var player = null
	if color != "gray":
		player = players[color]
	all_countries[country_name].synchronise(num_troops, player)

remote func synchronise_players_and_round(_curr_player_index, _round_number, player_info):
	for player in player_info:
		var curr_player = players[player["color"]]
		curr_player.network_id = player["network_id"]
		curr_player.num_reinforcements = player["num_reinforcements"]
		curr_player.update_labels()
	round_number = _round_number
	curr_player_index = _curr_player_index
	curr_player = players.values()[curr_player_index]
	update_labels()



var time_since_sync = 0
func _process(delta):
#	### TESTING
#	time_since_sync += delta
#	if time_since_sync > 3:
#		update_map_with_mask()
	
	# Skip synchronisation if not online
	if not _root.online_game:
		return
	
	time_since_sync += delta
	if time_since_sync > sync_period:
		print("syncing")
		
		var network_id = _root.players["guest"]
		if get_next_player().network_id != null:
			network_id = get_next_player().network_id
		
		# Synchronising the countries in terms of colors and troops
		for country in all_countries.values():
			var color = "gray"
			if country.belongs_to != null:
				color = country.belongs_to.color
			rpc_id(network_id, "synchronise_country", country.country_name, country.num_troops, color)
		
		# Synchrosing the game in terms of player informationa and meta info like round and curr player
		var player_info = []
		for player in players.values():
			player_info.append(player.save())
		rpc_id(network_id, "synchronise_players_and_round", curr_player_index, round_number, player_info)
		
		time_since_sync = 0
