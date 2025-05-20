extends Panel

func _ready():
	GameClock.time_updated.connect(_update_ui)
	_update_ui(GameClock.get_time_string())

func _update_ui(time_str: String):
	$Label.text = time_str
