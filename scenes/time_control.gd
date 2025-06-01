extends HBoxContainer

@onready var clock = get_node("../Clock")

func _ready(): 
	print("clock node = ", clock)

func _update_buttons(active_button: Button):
	for child in get_children():
		child.modulate = Color.WHITE
	active_button.modulate = Color(0.5, 0.5, 0.5, 1) 
	active_button.release_focus()

func _on_pause_pressed():
	clock.pause()
	_update_buttons($Pause)

func _on_play_pressed():
	clock.play()
	_update_buttons($Play)

func _on_fast_pressed():
	clock.fast()
	_update_buttons($Fast)

func _on_super_fast_pressed():
	clock.super_fast()
	_update_buttons($SuperFast)

func _input(event):
	if not visible:
		return

	if event.is_action_pressed("Pause"):
		_on_pause_pressed()
	elif event.is_action_pressed("Play"):
		_on_play_pressed()
	elif event.is_action_pressed("Fast"):
		_on_fast_pressed()
	elif event.is_action_pressed("SuperFast"):
		_on_super_fast_pressed()
