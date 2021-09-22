extends Camera2D

var mouse_start_pos
var screen_start_position

var dragging = false

func zoom_in():
	zoom *= 0.5

func zoom_out():
	# Prevent zooming out beyond full screen
	if zoom[0]*2 <=1:
		zoom *= 2
	# Center camera if already at max zoom
	else:
		position = Vector2(1,1)

func _input(event):
	if event is InputEventMouseButton:
		#if event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_position = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		# Ignore drag if the distance is less than 10 pixels.
		# This is to prevent a single touch with an accidental mouse movement being interpeted as a drag
		if event.position.distance_to(mouse_start_pos) > 10:
			position = zoom * (mouse_start_pos - event.position) + screen_start_position
