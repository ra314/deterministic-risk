extends Sprite

var colors = {"blue": load("res://Assets/Blue_Square.png"), 
				"red": load("res://Assets/Red_Square.png"),
				"gray": load("res://Assets/Gray_Square.png")}

func change_color_to(color):
	texture = colors[color]

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().belongs_to == null:
		texture = colors["gray"]
	else:
		texture = colors[get_parent().belongs_to.color]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
