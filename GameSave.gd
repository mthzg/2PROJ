extends Node

const SaveFilePath = "user://save_game.save"

var save_data = {}

func Save():
	save_data = {
		"minute": GameClock.minute,
		"hour": GameClock.hour,
		"day": GameClock.day,
		"month": GameClock.month,
		"year": GameClock.year
	}

	var file = FileAccess.open(SaveFilePath, FileAccess.WRITE)
	file.store_var(save_data)
	print("Game saved.")

func Load():
	if not FileAccess.file_exists(SaveFilePath):
		return
	var file = FileAccess.open(SaveFilePath, FileAccess.READ)
	save_data = file.get_var()

	GameClock.minute = save_data.get("minute", 0)
	GameClock.hour = save_data.get("hour", 0)
	GameClock.day = save_data.get("day", 1)
	GameClock.month = save_data.get("month", 0)
	GameClock.year = save_data.get("year", 0)
	print("Game loaded.")

func Reset():
	if FileAccess.file_exists(SaveFilePath):
		DirAccess.remove_absolute(SaveFilePath)
	print("Save file reset.")

func StartGame(is_new: bool):
	if is_new:
		GameClock.minute = 0
		GameClock.hour = 0
		GameClock.day = 1
		GameClock.month = 0
		GameClock.year = 0
	else:
		Load()
