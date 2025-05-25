extends CanvasLayer

@onready var clock = get_node("../CanvasLayer/Control/Clock")
const SAVE_FILE_PATH := "user://savegame.save"
var building_placement

@onready var MenuRoot = $MenuRoot  # The VBoxContainer or Panel holding all buttons

var menu_open := false
var citizen_count := 0
var buildings := []




func _ready():
	building_placement = get_node_or_null("../Terrain")
	if building_placement == null:
		print("Could not find BuildingPlacement node!")
	self.visible = false
	set_process_unhandled_input(true)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_open = !menu_open
		self.visible = menu_open
		print("Toggled menu. Now visible:", self.visible)

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
	menu_open = false

func _on_load_game_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var save_data = file.get_var()

			clock.minute = save_data.get("minute", 0)
			clock.hour = save_data.get("hour", 0)
			clock.day = save_data.get("day", 1)
			clock.month = save_data.get("month", 0)
			clock.year = save_data.get("year", 0)
			clock.play()

			citizen_count = save_data.get("citizens", 0)

			# Remove existing buildings if needed
			for building in buildings:
				building.queue_free()
			buildings.clear()
			building_placement.clear_buildings()
			

			for b_data in save_data.get("buildings", []):
				var cell = b_data["cell"]
				var type = b_data["type"]
				var building_data = building_placement.get_building_data_from_name(type)
				if building_data != null:
					building_placement.set_current_building(building_data)
					building_placement.try_place_building(cell)
				else:
					print("⚠ Unknown building type:", type)




			print("Game loaded:", save_data)
			self.visible = false



func _on_save_game_pressed():
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {
			"minute": clock.minute,
			"hour": clock.hour,
			"day": clock.day,
			"month": clock.month,
			"year": clock.year,
			"citizens": citizen_count,
			"buildings": []
		}

		for cell in building_placement.occupied_cells:
			var name = building_placement.occupied_cells[cell]
			save_data["buildings"].append({
				"type": name,
				"cell": cell
			})
		file.store_var(save_data)
		print("Game saved:", save_data)



func _on_reset_data_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save data reset.")

func _on_exit_pressed():
	get_tree().quit()
