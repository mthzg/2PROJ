extends Camera2D

var dragging := false
var zoom_speed := 0.1
var min_zoom := 1
var max_zoom := 10.0

func _ready():
	zoom = Vector2(1.5, 1.5)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(zoom_speed)
	
	elif event is InputEventMouseMotion and dragging:
		global_position -= event.relative * 0.5

func _zoom_camera(amount: float):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom
