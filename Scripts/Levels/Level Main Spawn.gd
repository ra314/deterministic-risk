extends Node
var P = null

func _ready():
	P = get_parent()

func spawn_and_allocate():
	# Creating players
	P.players = {"red": P.get_node("CanvasLayer/Player Red").init("red"), "blue": P.get_node("CanvasLayer/Player Blue").init("blue")}
	# Adding the neutral player
	P.players["gray"] = P.player_neutral
	
	reset_spawn()

	# Randomizing players
	randomize()
	P.curr_player_index = randi() % P.num_players
	P.curr_player = P.players.values()[P.curr_player_index]
	
	# Randomly allocating countries
	add_random_countries(P.get_next_player(), 4)
	add_random_countries(P.curr_player, 3)
	
	# Assigning the owned countries with a predetermined spread:
	var troops_to_assign = [2,2,3]
	for country in P.curr_player.owned_countries:
		country.set_initial_troops(P.select_random(troops_to_assign))
		troops_to_assign.erase(country.num_troops)
	
	troops_to_assign = [2,3,1,2]
	for country in P.get_next_player().owned_countries:
		country.set_initial_troops(P.select_random(troops_to_assign))
		troops_to_assign.erase(country.num_troops)
	
	# Checking if all player owned countries have a country they can attack
	for player in P.players.values().slice(0,1):
		for country in player.owned_countries:
			if country.num_troops > 1:
				if len(country.get_attackable_countries(["classic"])) == 0:
					print("BAD spawn, I have " + str(country.num_troops) + " units and am " + country.belongs_to.color)
					return false
	
	# Check that all player owned countries cannot immediately attack another player owned country
	for player in P.players.values().slice(0,1):
		for attacker in player.owned_countries:
			for defender in attacker.get_attackable_countries(["classic"]):
				if defender.belongs_to.color != "gray":
					print("BAD spawn, I have " + str(defender.num_troops) + " units and am " + defender.belongs_to.color + " and can be attacked")
					return false
	
	P.update_labels()
	P.Phase.update_player_status()
	print("Found good spawn")
	return true

# Clear the player dictionary, rerandomise troop allocation and redo player turn order and country allocation
func reset_spawn():
	for player in P.players.values():
		if player.color == "gray": continue
		player.reset()
	P.curr_player = null
	for country in P.all_countries.values():
		country.change_ownership_to(P.players["gray"])
		country.randomise_troops()

func add_random_countries(player, num_countries):
	# Checking that sufficient number of countries are available	
	if get_num_neutral_countries() < num_countries:
		print("not enough countries")
		get_tree().quit()
	
	# Adding random countries to the player
	var num_added_countries = 0
	var loop_counter = 0
	while num_added_countries < num_countries:
		loop_counter += 1
		var country = P.select_random(P.all_countries.values())
		if loop_counter > 1000:
			print("Not enough countries for all starting countries to be non adjacent.\n1000 iterations completed.")
			get_tree().quit()
		
		# Ensuring that the country is not adjacent to the opponent and is unowned
		if country.belongs_to.color == "gray" and not is_country_neighbour_of_player(country, P.get_next_player()):
			country.change_ownership_to(player)
			num_added_countries += 1
	P.update_labels()

func get_num_neutral_countries():
	var count = 0
	for country in P.all_countries.values():
		count += int(country.belongs_to.color == "gray")
	return count

# Checks if a country is non adjacent to a player
func is_country_neighbour_of_player(test_country, player):
	for country in player.owned_countries:
		if test_country in country.connected_countries:
			return true
	return false
