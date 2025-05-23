extends CanvasLayer

@onready var clock = get_node("../CanvasLayer/Control/Clock")

const SAVE_FILE_PATH := "user://savegame.save"

@onready var MainMenu = $MainMenu
@onready var SettingsMenu = $SettingsMenu

var settings_open := false

func _ready():

	MainMenu.visible = true
	SettingsMenu.visible = false
	set_process_unhandled_input(true)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		print("ESC pressed")  # Add this line for debugging
		_toggle_settings_menu()

func _toggle_settings_menu():
	settings_open = !settings_open

	print("Settings toggled. Open:", settings_open)
	print("SettingsMenu node:", SettingsMenu)
	print("MainMenu node:", MainMenu)
	print("SettingsMenu: visible =", SettingsMenu.visible)
	print("  size =", SettingsMenu.size)
	print("  position =", SettingsMenu.position)
	print("  modulate =", SettingsMenu.modulate)


	SettingsMenu.visible = settings_open
	MainMenu.visible = not settings_open

	SettingsMenu.visible = true
	SettingsMenu.position = Vector2(100, 100)
	SettingsMenu.size = Vector2(500, 300)
	SettingsMenu.modulate = Color(1, 0, 0, 1)  


func _on_new_game_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

	clock.minute = 0
	clock.hour = 0
	clock.day = 1
	clock.month = 0
	clock.year = 0
	clock.play()

	self.visible = false

func _on_load_game_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var save_data = file.get_var()

		clock.minute = save_data["minute"]
		clock.hour = save_data["hour"]
		clock.day = save_data["day"]
		clock.month = save_data["month"]
		clock.year = save_data["year"]
		clock.play()

		self.visible = false
	else:
		print("No save file found.")

func _on_save_game_pressed():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var save_data = {
		"minute": clock.minute,
		"hour": clock.hour,
		"day": clock.day,
		"month": clock.month,
		"year": clock.year,
	}
	file.store_var(save_data)

func _on_reset_data_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save data reset.")

func _on_exit_pressed():
	get_tree().quit()
