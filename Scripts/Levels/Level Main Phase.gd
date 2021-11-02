extends Node
var P = null
signal ending_reinforcement()
signal ending_attack()
signal ending_movement()

func _ready():
	P = get_parent()
	if "movement" in P.game_modes:
		connect("ending_attack", self, "start_movement1")
		connect("ending_movement", self, "start_reinforcement1")
	else:
		connect("ending_attack", self, "start_reinforcement1")
	# Updating player status
	connect("ending_attack", self, "update_player_status")
	connect("ending_reinforcement", self, "update_player_status")
	connect("ending_movement", self, "update_player_status")

func change_to_next_player():
	P.curr_player_index = (P.curr_player_index+1)%P.num_players
	P.curr_player = P.players.values()[P.curr_player_index]
	# We're synchronizing the current player because after the change 
	# the current player is no longer the instance this function was called on
#	if P._root.online_game:
#		P.get_node("Sync").synchronize(P.curr_player.network_id)
#		rpc_id(P.curr_player.network_id, "update_player_status")
	update_player_status()

# Update status to attack or defend
remote func update_player_status():
	var color = P.curr_player.color
	var attacking = P.phase == "attack"
	
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


func start_reinforcement1():
	rpc("start_reinforcement2")
remotesync func start_reinforcement2():
	P.curr_player.give_reinforcements()
	P.phase = "reinforcement"
	if P.is_current_player() or not P._root.online_game:
		P.show_end_reinforcement(true)
func end_reinforcement1(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool and P.curr_player.num_reinforcements > 0:
		P.show_confirmation_menu("You have a reinforcement left to place on the map.\nAre you sure you want to end reinforcement?",\
							 "end_reinforcement1", [true], self)
		return
	rpc("end_reinforcement2")
# The reason this wrapper function exists is because the buttons are connected to
# end_reinforcement1. There's no way to buttons to trigger a remote sync function all,
# Hence the need of a separate end_reinforcement2
remotesync func end_reinforcement2():
	# Modifying the visibility of the end attack and end reinforcement buttons
	P.show_end_reinforcement(false)
	if P._root.online_game:
		if not P.is_current_player():
			P.show_end_attack(true)
			notify()
	else:
		P.show_end_attack(true)

	P.set_selected_country(null) 
	
	P.round_number += 1
	change_to_next_player()
	P.update_labels()
	
	P.phase = "attack"
	emit_signal("ending_reinforcement")
	
	# Automatically end the attack phase if in checkers mode and no attacks are available
	if "checkers" in P.game_modes and P.is_attack_over():
		end_attack1(true)

func end_attack1(surity_bool=false):
	# When the surity bool is true, you get to skip the confirmation menu
	if not surity_bool:
		P.show_confirmation_menu("You have an attack left.\nAre you sure you want to end attacks?",\
							 "end_attack1", [true], self)
		return
	rpc("end_attack2")

# The reason this wrapper function exists is because the buttons are connected to
# end_attack1. There's no way to buttons to trigger a remote sync function all,
# Hence the need of a separate end_attack2
remotesync func end_attack2():
	P.set_selected_country(null) 
	P.curr_level.stop_flashing()
	# Modifying the visibility of the end attack and end reinforcement buttons
	if P.is_current_player() or not P._root.online_game:
		P.show_end_attack(false)
	emit_signal("ending_attack")

func start_movement1():
	rpc("start_movement2")
remotesync func start_movement2():
	P.phase = "movement"
	if P.is_current_player() or not P._root.online_game:
		P.show_end_movement(true)
func end_movement1():
	rpc("end_movement2")
remotesync func end_movement2():
	P.set_selected_country(null) 
	if P.is_current_player() or not P._root.online_game:
		P.show_end_movement(false)
	emit_signal("ending_movement")

remote func notify():
	$Notification.play()
