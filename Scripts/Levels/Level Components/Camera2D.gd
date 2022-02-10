extends Camera2D

var mouse_start_pos
var screen_start_position
var map_size

# Level 1 Zoom is 1x, Level 2 = 2x, Level 3 = 4x...
var zoom_level = 1

# The amount of time zooms take to tween into
const zoom_tween_duration = 0.5

var dragging = false

func _ready():
	make_current()

# Used after the map loads. This sets the scrolling limit of the camera so that doesn't go out of bounds
func setup_camera(camera_bounds):
	map_size = camera_bounds
	
	# Enable the drag margins to be dragged
	drag_margin_h_enabled = true
	drag_margin_v_enabled = true
	
	# Camera_bounds is divided by two because of thats the size of the $Camera2D node
	set_limit(MARGIN_LEFT, 0)
	set_limit(MARGIN_RIGHT, camera_bounds.x/2)
	set_limit(MARGIN_TOP, 0)
	set_limit(MARGIN_BOTTOM, camera_bounds.y/2)
	
	# Setup the drag margins
	set_drag_margin(MARGIN_LEFT, 1)
	set_drag_margin(MARGIN_RIGHT, 1)
	set_drag_margin(MARGIN_TOP, 1)
	set_drag_margin(MARGIN_BOTTOM, 1)

# Zoom functions now return a fixed zoom vector based on the zoom_level
# 2 ^ x - 1 where x > 0
func get_zoom_vector():
	return Vector2(1,1) / pow(2, zoom_level - 1)
	
func zoom_in():
	# Preventing zoom in beyond 8x
	if zoom_level < 4:
		zoom_level += 1
		tween_zoom(Vector2(1, 1) / pow(2, zoom_level - 1))

func zoom_out():
	# Prevent zooming out beyond 1x
	if zoom_level > 1:
		zoom_level -= 1
		tween_zoom(get_zoom_vector())

func zoom_to_level_with_duration(new_zoom, duration):
	# If a tween was active, stop the animation
	if ($Tween.is_active()):
		$Tween.stop(self)
	
	var new_center_pos = (position - get_camera_screen_center()) * (new_zoom / zoom) + get_camera_screen_center()

	$Tween.interpolate_property(self, "zoom", zoom, new_zoom, duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "position", position, new_center_pos, duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	
func tween_zoom(new_zoom):
	fix_drag_camera()
	zoom_to_level_with_duration(new_zoom, zoom_tween_duration)

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
			
			# The camera should not drag beyond the camera limits
			# This sets the final drag position (position) to the map limits
			fix_drag_camera()
				
func fix_drag_camera():
	var viewport_size = get_viewport().size
	
	if (position.x < 0): 
		position.x = 0
	elif (position.x > map_size.x/2 - (viewport_size * zoom).x):
		position.x = map_size.x/2 - (viewport_size * zoom).x
	
	if (position.y < 0):
		position.y = 0
	elif (position.y > map_size.y/2  - (viewport_size * zoom).y):
		position.y = map_size.y/2 - (viewport_size * zoom).y
