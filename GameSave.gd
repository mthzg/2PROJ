extends Node

@onready var clock = get_node("../Clock")

const SaveFilePath = "user://save_game.save"

var save_data = {}

func Save():
	save_data = {
		"minute": clock.minute,
		"hour": clock.hour,
		"day": clock.day,
		"month": clock.month,
		"year": clock.year
	}

	var file = FileAccess.open(SaveFilePath, FileAccess.WRITE)
	file.store_var(save_data)
	print("Game saved.")

func Load():
	if not FileAccess.file_exists(SaveFilePath):
		return
	var file = FileAccess.open(SaveFilePath, FileAccess.READ)
	save_data = file.get_var()

	clock.minute = save_data.get("minute", 0)
	clock.hour = save_data.get("hour", 0)
	clock.day = save_data.get("day", 1)
	clock.month = save_data.get("month", 0)
	clock.year = save_data.get("year", 0)
	print("Game loaded.")

func Reset():
	if FileAccess.file_exists(SaveFilePath):
		DirAccess.remove_absolute(SaveFilePath)
	print("Save file reset.")

func StartGame(is_new: bool):
	if is_new:
		clock.minute = 0
		clock.hour = 0
		clock.day = 1
		clock.month = 0
		clock.year = 0
	else:
		Load()
