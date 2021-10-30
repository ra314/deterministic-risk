extends Node
var P = null

func _ready():
	P = get_parent()

func change_to_next_player():
	P.curr_player_index = (P.curr_player_index+1)%P.num_players
	P.curr_player = P.players.values()[P.curr_player_index]
	# We're synchronizing the current player because after the change 
	# the current player is no longer the instance this function was called on
	if P._root.online_game:
		P.get_node("Sync").synchronize(P.curr_player.network_id)
		rpc_id(P.curr_player.network_id, "update_player_status", P.curr_player.color, P.phase == "attack")

# Update status to attack or defend
remote func update_player_status(color, attacking):	
	# Reset existing player statuses
	P.get_node("CanvasLayer/Game Info/red/VBoxContainer/Status").visible = false
	P.get_node("CanvasLayer/Game Info/blue/VBoxContainer/Status").visible = false
	
	# Selecting attack or defend for player status
	var curr_player_status = P.get_node("CanvasLayer/Game Info/" + color + "/VBoxContainer/Status")
	curr_player_status.visible = true
	if attacking:
		curr_player_status.texture = load("res://Assets/Icons/sword.svg")
	else:
		curr_player_status.texture = load("res://Assets/Icons/shield.svg")

remote func change_to_reinforcement(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool:
		P.show_confirmation_menu("You have an attack left.\nAre you sure you want to end attacks?",\
							 "change_to_reinforcement", [true], self)
		return
	
	P.selected_country = null
	P.curr_level.stop_flashing()
	P.curr_player.give_reinforcements()
	
	# Disabling resistance and blitz
	for country in P.all_countries.values():
		country.reset_status()
	
	# Modifying the visibility of the end attack and end reinforcement buttons
	P.end_attack_disable(true)
	P.end_reinforcement_disable(false)
	
	# Updating player status
	update_player_status(P.curr_player.color, false)
	
	P.phase = "reinforcement"

func change_to_attack(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool and P.curr_player.num_reinforcements > 0:
		P.show_confirmation_menu("You have a reinforcement left to place on the map.\nAre you sure you want to end reinforcement?",\
							 "change_to_attack", [true], self)
		return
	
	# Modifying the visibility of the end attack and end reinforcement buttons	
	if P._root.online_game:
		P.end_reinforcement_disable(true)
		rpc_id(P.get_next_player().network_id, "end_attack_disable", false)
		rpc_id(P.get_next_player().network_id, "notify")
	else:
		P.end_attack_disable(false)
		P.end_reinforcement_disable(true)
	
	# Moving the troops from reinforcement into active duty for each country
	# and subtracting pandemic deaths
	for country in P.all_countries.values():
		country.set_num_troops(country.num_troops + country.num_reinforcements)
		country.set_num_reinforcements(0)
		if "pandemic" in P.game_modes:
			country.set_num_troops(country.num_troops - country.calc_pandemic_deaths())
	
	P.selected_country = null
	P.round_number += 1
	P.phase = "attack"
	change_to_next_player()
	P.update_labels()
	
	# Updating player status
	update_player_status(P.curr_player.color, true)
	
	# Automatically end the attack phase if in checkers mode and no attacks are available
	if "checkers" in P.game_modes and P.is_attack_over():
		if P._root.online_game:
			rpc_id(P.curr_player.network_id, "change_to_reinforcement", true)
		else:
			change_to_reinforcement(true)

remote func notify():
	$Notification.play()
