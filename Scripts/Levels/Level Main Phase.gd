extends Node
var P = null
signal ending_reinforcement()
signal ending_attack()

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

func change_to_attack1(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool and P.curr_player.num_reinforcements > 0:
		P.show_confirmation_menu("You have a reinforcement left to place on the map.\nAre you sure you want to end reinforcement?",\
							 "change_to_attack1", [true], self)
		return
	rpc("change_to_attack2")

# The reason this wrapper function exists is because the buttons are connected to
# change_to_attack1. There's no way to buttons to trigger a remote sync function all,
# Hence the need of a separate change_to_attack2
remotesync func change_to_attack2():
	# Modifying the visibility of the end attack and end reinforcement buttons	
	if P._root.online_game:
		if P.is_current_player():
			P.show_end_reinforcement(false)
			rpc_id(P.get_next_player().network_id, "show_end_attack", true)
			rpc_id(P.get_next_player().network_id, "notify")
	else:
		P.show_end_reinforcement(false)
		P.show_end_attack(true)

	emit_signal("ending_reinforcement")
	P.selected_country = null
	P.round_number += 1
	P.phase = "attack"
	change_to_next_player()
	P.update_labels()
	
	# Updating player status
	update_player_status(P.curr_player.color, true)
	
	# Automatically end the attack phase if in checkers mode and no attacks are available
	if "checkers" in P.game_modes and P.is_attack_over():
		change_to_reinforcement1(true)

func change_to_reinforcement1(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool:
		P.show_confirmation_menu("You have an attack left.\nAre you sure you want to end attacks?",\
							 "change_to_reinforcement1", [true], self)
		return
	rpc("change_to_reinforcement2")

# The reason this wrapper function exists is because the buttons are connected to
# change_to_reinforcement1. There's no way to buttons to trigger a remote sync function all,
# Hence the need of a separate change_to_reinforcement2
remotesync func change_to_reinforcement2():
	P.selected_country = null
	P.curr_level.stop_flashing()
	P.curr_player.give_reinforcements()
	emit_signal("ending_attack")
	
	# Modifying the visibility of the end attack and end reinforcement buttons
	if P.is_current_player() or not P._root.online_game:
		P.show_end_attack(false)
		P.show_end_reinforcement(true)
	
	# Updating player status
	update_player_status(P.curr_player.color, false)
	
	P.phase = "reinforcement"
	return

remote func notify():
	$Notification.play()
