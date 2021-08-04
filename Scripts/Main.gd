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
var players = {}

remotesync func load_level(scene_str, world_str):
	var scene = scene_manager._load_scene(scene_str)
	scene.load_world(world_str)
	scene_manager._replace_scene(scene)
	print("uwu :)")

func _ready():
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

remote func register_player(player_name):	
	# Registering self, since no name was provided
	players[player_name] = get_tree().get_rpc_sender_id()

func host():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer

func guest(server_IP):
	if not server_IP:
		server_IP = LOCAL_HOST
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_IP, SERVER_PORT)
	get_tree().network_peer = peer

	print(server_IP)
