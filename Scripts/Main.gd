extends Node2D

class_name Main

var scene_manager: SceneManager = SceneManager.new(self)

var online_game = false
var player_name = ""
var network_data = {}

var peer = null
const SERVER_PORT = 9658
const MAX_PLAYERS = 2
const LOCAL_HOST = "127.0.0.1"
# Dictionary mapping player names ("host", "guest") to network ids
var players = {}



remotesync func load_level(scene_str, world_str):
	var scene = scene_manager._load_scene(scene_str).init(world_str)
	scene_manager._replace_scene(scene)
	print("uwu :)")

func _ready():
	# The event that triggers when a player connects to this instance of the game
	get_tree().connect("network_peer_connected", self, "_player_connected")
	
	var scene = scene_manager._load_scene("UI/Local Online")
	scene_manager._replace_scene(scene)

# Callback from SceneTree.
func _player_connected(id):
	# Adding yourself to the list of players if not already there
	if not player_name in players.keys():
		players[player_name] = get_tree().get_network_unique_id()

	# Registering the new player that connected
	rpc_id(id, "register_player", player_name)

# Register a player to a dictionary that contains player names and player ids
remote func register_player(player_name):	
	players[player_name] = get_tree().get_rpc_sender_id()

# Create a server and set the network peer to the peer you created
func host():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer

func guest(server_IP):
	# Default of 127.0.0.1
	if not server_IP:
		server_IP = LOCAL_HOST
	# Create a client and set the network peer to the peer you created
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_IP, SERVER_PORT)
	get_tree().network_peer = peer

	print(server_IP)
