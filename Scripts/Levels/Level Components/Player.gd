extends Node2D
var owned_countries = []
var num_reinforcements = 0
var color = null
var network_id = null

func save():
	var save_dict = {}
	save_dict["network_id"] = network_id
	save_dict["color"] = color
	save_dict["num_reinforcements"] = num_reinforcements
	return save_dict

func init(_color, _x, _y):
	self.color = _color
	position = Vector2(_x, _y)
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
	update_labels()

func update_labels():
	var player_name = "Player: "
	if network_id != null:
		if network_id == 1:
			player_name = "Host: "
		else:
			player_name = "Guest: "
	get_node("Label").text = player_name + color + \
		"\nUnits: " + str(get_num_troops()) + \
		"\nReinforcements: " + str(num_reinforcements) + "/" + str(get_num_reinforcements()) + \
		"\nNumber of Countries: " + str(len(owned_countries))

# Called when the node enters the scene tree for the first time.
func _ready():
	update_labels()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
