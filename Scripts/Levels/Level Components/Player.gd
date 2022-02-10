extends Node2D
var owned_countries = []
var num_reinforcements = 0
var color = ""
var network_id = null

func save():
	var save_dict = {}
	save_dict["color"] = color
	save_dict["owned_countries"] = []
	var owned_countries_names = []
	for country in owned_countries:
		owned_countries_names.append(country.country_name)
	owned_countries_names.sort()
	save_dict["owned_countries"].append_array(owned_countries_names)
	return save_dict

func reset():
	# Ownership of the old country goes to player_nuetral
	for country in owned_countries.duplicate():
		country.change_ownership_to(country.Game_Manager.player_neutral)
	
	owned_countries = []
	num_reinforcements = 0
	network_id = null

func init(_color):
	self.color = _color
	return self

func get_num_troops():
	var num_troops = 0
	for country in owned_countries:
		num_troops += country.num_troops
	return num_troops

func get_num_reinforcements():
	return int(ceil(float(len(owned_countries))/2))

func give_reinforcements():
	num_reinforcements = get_num_reinforcements()
