extends Node2D

class_name Main

var scene_manager: SceneManager = SceneManager.new(self)

var online_game = false
var player_name = ""
var network_data = {}
var game_modes = []
var stored_IP = ""
var game_started: bool = false
var disconnection_container = null

var peer = null
const SERVER_PORT = 9658
const MAX_PLAYERS = 2
const LOCAL_HOST = "127.0.0.1"
# Dictionary mapping player names ("host", "guest") to network ids
var players = {}

func get_other_player_network_id():
	var player_keys = players.keys()
	player_keys.erase(player_name)
	return players[player_keys[0]]

remotesync func load_level(scene_str, world_str, game_modes):
	var scene = scene_manager._load_scene(scene_str)
	scene._root = self
	scene.game_modes = game_modes
	scene.world_str = world_str
	scene_manager._replace_scene(scene)
	game_started = true

func _ready():
	# The event that triggers when a player connects to this instance of the game
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	var scene = scene_manager._load_scene("UI/Local Online")
	scene_manager._replace_scene(scene)

# Register a player to a dictionary that contains player names and player ids
remote func register_player(player_name, id):	
	players[player_name] = id
	create_notification(player_name + " has connected")
	# Remove the back button for the host once the guest has connected
	get_children()[0].get_node("TextureButton").visible = false

# General purpose notification system
####### 
var notifications = []

func create_notification(notification_str):
	var notification = Label.new()
	notification.text = notification_str
	notification.add_font_override("font", load("res://Assets/Fonts/Font_50.tres"))
	add_child(notification)
	notifications.append(notification)
	get_tree().create_timer(2).connect("timeout", self, "delete_last_notification")

func delete_last_notification():
	var notification = notifications.pop_back()
	remove_child(notification)
	notification.queue_free()
#######

# Create a server and set the network peer to the peer you created
func host():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	
	# Adding yourself to the list of players
	if online_game:
		register_player(player_name, get_tree().get_network_unique_id())

func guest(server_IP):
	# Default of 127.0.0.1
	if not server_IP:
		server_IP = LOCAL_HOST
	# Create a client and set the network peer to the peer you created
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_IP, SERVER_PORT)
	get_tree().network_peer = peer
	
	# Adding yourself to the list of players 
	register_player(player_name, get_tree().get_network_unique_id())

func load_save(save_dict):
	# Setting up the game
	game_modes = save_dict["game_modes"]
	rpc("load_level", "Levels/Level Main", save_dict["map"],  game_modes)
	
	# Setting up curr_player and curr_player_index
	var main = get_children()[0]
	main.curr_player = main.players[save_dict["curr_player_color"]]
	# Finding the current player index
	var players_colors = []
	for player in main.players.values():
		players_colors.append(player.color)
	main.curr_player_index = players_colors.find(save_dict["curr_player_color"])
	
	# Assigning all countries their saved properties
	for country_dict in save_dict["countries"]:
		var country = main.all_countries[country_dict["name"]]
		country.set_max_troops(country_dict["max_troops"])
		country.set_num_troops(country_dict["troops"])
		for status in country_dict["status"]:
			country.set_statused(status, country_dict["status"][status])
	
	# Assigning ownership of countries to players
	for player_dict in save_dict["players"]:
		var player = main.players[player_dict["color"]]
		player.reset()
		for country_name in player_dict["owned_countries"]:
			main.all_countries[country_name].change_ownership_to(player)
	
	if online_game:
		main.Sync.synchronize_all(players["guest"])
	main.update_labels()
	main.Phase.update_player_status()

# NETWORKING CALLBACKS
#######
# Callback from SceneTree.
func _player_connected(id):
	# Registering the new player that connected
	rpc_id(id, "register_player", player_name, get_tree().get_network_unique_id())

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	disconnection_routine("The guest has disconnected.\nStart a new game.\nOr start a new game and load the last save.")

# Callback from SceneTree.
func _player_disconnected(id):
	disconnection_routine("The host has disconnected.\nStart a new game.\nOr start a new game and load the last save.")

func disconnection_routine(message_str):
	var notification = Label.new()
	notification.text = message_str
	notification.add_font_override("font", load("res://Assets/Fonts/Font_50.tres"))
	notification.add_stylebox_override("normal", load("res://Assets/label_background.tres"))
	
	var button = Button.new()
	button.text = "Start a new game"
	button.connect("button_down", self, "hard_reboot") 
	button.add_font_override("font", load("res://Assets/Fonts/Font_50.tres"))
	
	disconnection_container = CanvasLayer.new()
	add_child(disconnection_container)
	
	var centerbox = CenterContainer.new()
	centerbox.rect_size = Vector2(1920,1080)
	disconnection_container.add_child(centerbox)
	
	var vbox = VBoxContainer.new()
	centerbox.add_child(vbox)
	vbox.add_child(notification)
	vbox.add_child(button)
	
	if game_started:
		scene_manager._get_curr_scene().stop_game()

# Send the player to the first relevant UI menu and nuke game data
func hard_reboot():
	scene_manager.reset()
	var scene = scene_manager._load_scene("UI/Local Online")
	scene_manager._replace_scene(scene)
	remove_child(disconnection_container)
	disconnection_container.queue_free()
	disconnection_container = null
#######
