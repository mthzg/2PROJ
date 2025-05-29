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
		"year": clock.year,
		"buildings" : []
	}
	var buildings_node = get_tree().root.get_node("Node2D/Terrain")
	if buildings_node:
		var already_saved = {}
		for cell in buildings_node.occupied_cells.keys():
			var name = buildings_node.occupied_cells[cell]
			var building_data = buildings_node.get_building_data_from_name(name)
			if building_data:
				var size = building_data.get("size", Vector2i(1, 1))
				var is_origin = true
				for dx in range(size.x):
					for dy in range(size.y):
						var candidate = cell - Vector2i(dx, dy)
						if (dx > 0 or dy > 0) and buildings_node.occupied_cells.get(candidate, "") == name:
							is_origin = false
				if is_origin and not already_saved.has(cell):
					save_data["buildings"].append({
						"type": name,  # or "name"
						"cell": cell
					})
					already_saved[cell] = true

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
	var buildings_node = get_tree().root.get_node("Node2D/Terrain")
	if buildings_node:
		buildings_node.clear_buildings()  # Remove current buildings

	for building in save_data.get("buildings", []):
		var name = building.get("type")  # not "name" if you changed key above!
		var cell = building.get("cell")
		var building_data = buildings_node.get_building_data_from_name(name)
		if building_data:
			buildings_node.place_building_direct(cell, building_data)
	
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
