extends CanvasLayer

func _on_new_game_pressed():
	# Remove existing save if you want a true fresh start
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

	# Initialize default game values
	GameClock.minute = 0
	GameClock.hour = 0
	GameClock.day = 1
	GameClock.month = 0
	GameClock.year = 0
	GameClock.play()

	# Hide main menu and start the game
	self.visible = false


func _on_load_game_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var save_data = file.get_var()

		GameClock.minute = save_data["minute"]
		GameClock.hour = save_data["hour"]
		GameClock.day = save_data["day"]
		GameClock.month = save_data["month"]
		GameClock.year = save_data["year"]
		GameClock.play()

		self.visible = false
	else:
		print("No save file found.")
