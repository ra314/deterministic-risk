extends Sprite

var colors = {"blue": load("res://Assets/blue-square.svg"), 
				"red": load("res://Assets/red-pentagon-3.svg"),
				"gray": load("res://Assets/neutral-circle.svg")}

func change_color_to(color):
	texture = colors[color]

# Called when the node enters the scene tree for the first time.
func _ready():
	texture = colors[get_parent().belongs_to.color]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
