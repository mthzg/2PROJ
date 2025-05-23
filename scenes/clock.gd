extends Panel

signal time_updated(current_time: String)

enum Speed { PAUSE, PLAY, FAST, SUPER_FAST }
var speed := Speed.PLAY

var minute := 0
var hour := 0
var day := 1
var month := 0
var year := 0

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var timer := Timer.new()

func _ready():
	#GameClock.time_updated.connect(_update_ui)
	#_update_ui(GameClock.get_time_string())
	# Setup timer
	timer.one_shot = false
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()
	
	# Initialize UI with current time string
	_update_ui(get_time_string())

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]

func get_date_string() -> String:
	return "%s %d, Year %d" % [MONTH_NAMES[month], day, year]

func get_full_datetime_string() -> String:
	return "%02d:%02d, %s %d, Year %d" % [hour, minute, MONTH_NAMES[month], day, year]

func _on_timer_timeout():
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	if hour >= 24:
		hour = 0
		day += 1
	if day > 30:
		day = 1
		month += 1
	if month > 11:
		month = 0
		year += 1

	_emit_time()
	_update_ui(get_time_string())

func _emit_time():
	var time_string := get_full_datetime_string()
	emit_signal("time_updated", time_string)

func _update_ui(time_str: String):
	$Label.text = time_str

func set_speed(new_speed: Speed):
	speed = new_speed	
	match speed:
		Speed.PAUSE:
			timer.stop()
		Speed.PLAY:
			timer.wait_time = 1.0
			timer.start()
		Speed.FAST:
			timer.wait_time = 0.3
			timer.start()
		Speed.SUPER_FAST:
			timer.wait_time = 0.1
			timer.start()
	print("wait time =  ", timer.wait_time)
	

func pause(): set_speed(Speed.PAUSE)
func play(): set_speed(Speed.PLAY)
func fast(): set_speed(Speed.FAST)
func super_fast(): set_speed(Speed.SUPER_FAST)
