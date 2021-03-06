extends Node
var P = null

func _ready():
	P = get_parent()

func synchronize_all(network_id):
	# Synchronising the countries in terms of colors and troops
	for country in P.all_countries.values():
		rpc_id(network_id, "synchronise_country", country.country_name, \
			country.num_troops, country.num_reinforcements, \
			country.belongs_to.color, country.statused, country.max_troops)
	
	# Synchronising the game in terms of player information
	for player in P.players.values():
		rpc_id(network_id, "synchronise_player", player.color, player.network_id, player.num_reinforcements)
	
	# Synchronising meta information
	rpc_id(network_id, "synchronise_meta_info", P.curr_player_index, \
		P.round_number, P.game_started, P.game_modes)

remote func synchronize_country_click(country_name, event, is_long_press):
	P.all_countries[country_name].on_click(event, is_long_press)

func synchronize_raze1(country_name):
	rpc("synchronize_raze2", country_name)

remotesync func synchronize_raze2(country_name):
	P.all_countries[country_name].raze()

remote func synchronise_country(country_name, num_troops, num_reinforcements, color, statused, max_troops):
	P.all_countries[country_name].synchronise(num_troops, num_reinforcements, \
		P.players[color], statused, max_troops)

remote func synchronise_player(color, network_id, num_reinforcements):
	var curr_player = P.players[color]
	curr_player.network_id = network_id
	curr_player.num_reinforcements = num_reinforcements

remote func synchronise_meta_info(_curr_player_index, _round_number, _game_started, _game_modes):
	P.game_modes = _game_modes
	P.game_started = _game_started
	P.round_number = _round_number
	P.curr_player_index = _curr_player_index
	P.curr_player = P.players.values()[P.curr_player_index]
	P.update_labels()
	P.Phase.update_player_status()

# Verifying synchronization
#######
remote var other_players_hash_value = null

func games_are_synced():
	rpc_id(P._root.get_other_player_network_id(), "hash_and_return_over_network")
	yield(get_tree().create_timer(2), "timeout")
	return hash_game_state() == other_players_hash_value

remote func hash_and_return_over_network():
	rset_id(get_tree().get_rpc_sender_id(), "other_players_hash_value", hash_game_state())

func hash_game_state():
	return P.save().hash()
#######
