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
			print("citizen_count on load:", citizen_count)

			for building in buildings:
				building.queue_free()
			buildings.clear()
			building_placement.clear_buildings()

			for b_data in save_data.get("buildings", []):
				var cell = b_data["cell"]
				var type = b_data["type"]
				var building_data = building_placement.get_building_data_from_name(type)
				if building_data != null:
					building_placement.place_building_direct(cell, building_data)
					var success = building_placement.try_place_building(cell)
					if not success:
						print("❌ Failed to place building:", type, "at", cell)
				else:
					print("⚠ Unknown building type:", type)

			for c in building_placement.get_children():
				if "Citizen" in str(c):
					c.queue_free()

			print("Spawning citizens...")
			for i in range(citizen_count):
				building_placement.spawn_citizens()

			print("Game loaded:", save_data)
			self.visible = false




func _on_save_game_pressed():
	citizen_count = 0
	for c in building_placement.get_children():
		if "Citizen" in str(c): 
			citizen_count += 1

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

		var already_saved = {}
		for cell in building_placement.occupied_cells:
			var name = building_placement.occupied_cells[cell]
			if typeof(name) == TYPE_OBJECT and name.has_meta("building_name"):
				name = name.get_meta("building_name")
			var building_data = building_placement.get_building_data_from_name(name)
			if building_data:
				var size = building_data.get("size", Vector2i(1, 1))
				var is_origin = true
				for dx in range(size.x):
					for dy in range(size.y):
						var candidate = cell - Vector2i(dx, dy)
						var occ = building_placement.occupied_cells.get(candidate, "")
						if typeof(occ) == TYPE_OBJECT and occ.has_meta("building_name"):
							occ = occ.get_meta("building_name")
						if (dx > 0 or dy > 0) and occ == name:
							is_origin = false
				if is_origin and not already_saved.has(cell):
					save_data["buildings"].append({
						"type": name,
						"cell": cell
					})
					already_saved[cell] = true

		file.store_var(save_data)
		print("Game saved:", save_data)


func _on_reset_data_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save data reset.")

func _on_exit_pressed():
	get_tree().quit()
