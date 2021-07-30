extends "res://Scripts/Level_Funcs.gd"

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

var end_attack_button = null
var end_reinforcement_button = null
var round_number_label = null

var curr_player = null
var curr_player_index = null
const num_players = 2
var Player = load("res://Scenes/Levels/Level Components/Player.tscn")
var players = null

var peer = null
const SERVER_PORT = 9658
const MAX_PLAYERS = 2
const SERVER_IP = "127.0.0.1"
const IS_SERVER = true

func get_next_player():
	return players[(curr_player_index+1)%num_players]

func change_to_next_player():
	curr_player_index = (curr_player_index+1)%num_players
	curr_player = players[curr_player_index]

func init_multiplayer():
	if IS_SERVER:
		peer = NetworkedMultiplayerENet.new()
		peer.create_server(SERVER_PORT, MAX_PLAYERS)
		get_tree().network_peer = peer
	else:
		peer = NetworkedMultiplayerENet.new()
		peer.create_client(SERVER_IP, SERVER_PORT)
		get_tree().network_peer = peer

remote func poppdie():
	print("started networking boss")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	# Loading existing level
	if .import_level(self):
		print("imported")
	# Load the default half complete earth level
	else:
		.create_default_level(self)
	
	print(curr_level.all_countries)
	
	# Creating players
	players = [Player.instance().init("red", 200, 0), Player.instance().init("blue", 400, 0)]
	for player in players:
		add_child(player)
	
	# Randomizing players
	randomize()
	curr_player_index = randi() % num_players
	curr_player = players[curr_player_index]
	
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
	
	# Button to end attack
	end_attack_button = Button.new()
	end_attack_button.text = "End Attack Phase"
	end_attack_button.connect("pressed", self, "change_to_reinforcement")
	add_child(end_attack_button)
	
	# Button to end reinforcement
	end_reinforcement_button = Button.new()
	end_reinforcement_button.text = "End Reinforcement Phase"
	end_reinforcement_button.connect("pressed", self, "change_to_attack")
	add_child(end_reinforcement_button)
	end_reinforcement_button.visible = false
	end_reinforcement_button.set_position(Vector2(100, 0))
	
	get_node("Label").set_position(Vector2(get_viewport().size.x/2, 0))
	update_labels()

func select_random(array):
	return array[randi() % len(array)]

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
	
	end_attack_button.visible = false
	end_reinforcement_button.visible = true
	phase = "reinforcement"

func change_to_attack():
	if round_number == 10:
		end_game()
		return
	
	reinforced_countries.clear()
	
	change_to_next_player()
	round_number += 1
	update_labels()
	
	end_attack_button.visible = true
	end_reinforcement_button.visible = false
	phase = "attack"

func get_player_with_most_troops():
	var player_with_most_troops = null
	var max_num_troops = 0
	for player in players:
		if player.get_num_troops() > max_num_troops:
			player_with_most_troops = player
			max_num_troops = player.get_num_troops()
	return player_with_most_troops

func end_game():
	end_attack_button.visible = false
	end_reinforcement_button.visible = false
	phase = "game over"
	get_node("Label").text = get_player_with_most_troops().color + " Wins"

func update_labels():
	get_node("Label").text = "Player: " + curr_player.color + "\nRound: " + str(round_number)

