extends Node
var P = null

func _ready():
	P = get_parent()

func synchronize(network_id):
	print("syncing")
	
	# Synchronising the countries in terms of colors and troops
	for country in P.all_countries.values():
		rpc_id(network_id, "synchronise_country", country.country_name, \
			country.num_troops, country.num_reinforcements, \
			country.belongs_to.color, country.statused, country.max_troops)
	
	# Synchrosing the game in terms of player information
	for player in P.players.values():
		rpc_id(network_id, "synchronise_player", player.save())
	
	# Synchronising meta information
	rpc_id(network_id, "synchronise_meta_info", P.curr_player_index, \
		P.round_number, P.game_started, P.game_modes)

remote func synchronize_country_click(country_name, event, is_long_press):
	P.all_countries[country_name].on_click(event, is_long_press)

remote func synchronise_country(country_name, num_troops, num_reinforcements, color, statused, max_troops):
	P.all_countries[country_name].synchronise(num_troops, num_reinforcements, \
		P.players[color], statused, max_troops)

remote func synchronise_player(player_info):
	var curr_player = P.players[player_info["color"]]
	curr_player.network_id = player_info["network_id"]
	curr_player.num_reinforcements = player_info["num_reinforcements"]

remote func synchronise_meta_info(_curr_player_index, _round_number, _game_started, _game_modes):
	P.game_modes = _game_modes
	P.game_started = _game_started
	P.round_number = _round_number
	P.curr_player_index = _curr_player_index
	P.curr_player = P.players.values()[P.curr_player_index]
	P.update_labels()
