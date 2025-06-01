extends TileMap

signal building_selected(cell: Vector2i, building_data: Dictionary)

@onready var ground_layer := get_node("Ground")
@onready var rocks_layer := get_node("Rocks")
@onready var water_layer := get_node("Water")
@onready var hud_control = get_node("../CanvasLayer/Control")
var citizen_scene := preload("res://scenes/Buildings/Citizen.tscn")

var main_game  
var tile_size: Vector2 = Vector2(16, 16)
var occupied_cells = {}
var road_positions: = {}
var work_spot_cells = {}
var citizen_house_position: Vector2i
var buildings = {} 
var greatfire_place: bool = false


var ghost_cell = Vector2i.ZERO
var is_ghost_active = false

var current_building_data = null
var max_citizens = null

var house_built_count = 0
var free_house_limit = 5

var houses = []
var unassigned_citizens = [] 




func get_worker_stats_for(resource_type: String) -> Dictionary:
	var total_max = 0
	var total_current = 0
	for spot_cell in work_spot_cells.keys():
		var spot = work_spot_cells[spot_cell]
		if spot.type == resource_type:
			total_max += spot.max_workers
			total_current += spot.current_workers
	var temp = {
		"total_max": total_max,
		"current": total_current
	}
	print(temp)
	return temp

func spawn_30_trees():
	var placed = 0
	var map_bounds = ground_layer.get_used_rect()

	while placed < 60:
		var rand_x = randi() % map_bounds.size.x + map_bounds.position.x
		var rand_y = randi() % map_bounds.size.y + map_bounds.position.y
		var cell = Vector2i(rand_x, rand_y)

		if occupied_cells.has(cell):
			continue
		
		var ground_tile = ground_layer.get_cell_source_id(cell)
		var rocks_tile = rocks_layer.get_cell_source_id(cell)
		var water_tile = water_layer.get_cell_source_id(cell)
		if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
			continue

		var tree_scene = preload("res://scenes/Buildings/Tree.tscn")
		var instance = tree_scene.instantiate()
		instance.set_meta("building_name", "Tree")
		var local_pos = ground_layer.map_to_local(cell)
		instance.global_position = ground_layer.to_global(local_pos)
		add_child(instance)
		occupied_cells[cell] = instance
		buildings[instance] = [cell]
		work_spot_cells[cell] = {
			"type": "tree",
			"max_workers": 1,
			"current_workers": 0,
			"is_startup": true  # 
		}
		

		placed += 1

func _ready():
	spawn_30_trees()
	


func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_ghost_active:
			print("cancel placement")
			is_ghost_active = false
			ghost_cell = null
			current_building_data = null
			self.queue_redraw()
		return

	# Left click events
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var clicked_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))
		
		if is_ghost_active and ghost_cell != null:
			if try_place_building(ghost_cell):
				pass
			self.queue_redraw()
			if current_building_data != null and current_building_data.get("name") == "Eraser":
				delete_building_at(clicked_cell)
				return 
		elif not is_ghost_active:
			if occupied_cells.has(clicked_cell):
				var cell_value = occupied_cells[clicked_cell]
				var building_name = ""
				if typeof(cell_value) == TYPE_STRING:
					building_name = cell_value
				elif typeof(cell_value) == TYPE_OBJECT and cell_value.has_meta("building_name"):
					building_name = cell_value.get_meta("building_name")
				else:
					building_name = ""
				var data = get_building_data_from_name(building_name)
				if work_spot_cells.has(clicked_cell):
					data["work_spot"] = work_spot_cells[clicked_cell]
				emit_signal("building_selected", clicked_cell, data)


func _process(_delta):
	if is_ghost_active:
		var mouse_pos = get_global_mouse_position()
		ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))
		self.queue_redraw()
		

func _draw():
	if is_ghost_active and ghost_cell != null and current_building_data != null:
		var size = current_building_data.get("size", Vector2i(1, 1))  # Default 1x1
		for x in range(size.x):
			for y in range(size.y):
				var offset = Vector2(x, y) * tile_size
				var pos = (Vector2(ghost_cell.x, ghost_cell.y) * tile_size) + offset
				draw_rect(Rect2(pos, tile_size), Color(0.2, 0.4, 1.0, 0.3), true)

func try_place_building(cell: Vector2i) -> bool:
	if current_building_data == null:
		return false

	var size = current_building_data.get("size", Vector2i(1, 1))

	for x in range(size.x):
		for y in range(size.y):
			var check_cell = cell + Vector2i(x, y)

			var ground_tile = ground_layer.get_cell_source_id(check_cell)
			var rocks_tile = rocks_layer.get_cell_source_id(check_cell)
			var water_tile = water_layer.get_cell_source_id(check_cell)

			if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
				print("❌ Cannot place; blocked at cell ", check_cell)
				return false

			if check_cell in occupied_cells:
				print("❌ Cannot place; occupied at cell ", check_cell)
				return false

	var base_cost = current_building_data.get("cost", {})
	var cost = base_cost.duplicate(true)  


	if current_building_data.get("name") == "Small House" and house_built_count < free_house_limit:
		cost["wood"] = 0
		
	if current_building_data.get("name") == "Water Workers Hut":
		if not is_next_to_water(cell, size):
			print("❌ Water Workers Hut must be placed next to water!")
			return false
	
	
	if current_building_data.get("name") == "Greatfire":
		if greatfire_place:
			return false
	if main_game != null:
		for resource_name in cost.keys():
			var amount = cost[resource_name]
			if resource_name == "wood":
				if not main_game.can_spend_wood(amount):
					print("❌ Not enough wood to place building!")
					return false
			else:
				pass

	if main_game != null:
		for resource_name in cost.keys():
			var amount = cost[resource_name]
			if resource_name == "wood":
				main_game.spend_wood(amount)

	print("✅ Placing building at ", cell)
	place_building(cell, size)
	return true
	
	if current_building_data.get("name") == "Berry Picker":
		if not has_enough_berry_bushes(cell):
			print("❌ Not enough berry bushes nearby to place Berry Picker!")
			return false
			


			
			
func is_next_to_water(cell: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var current_cell = cell + Vector2i(x, y)

			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var neighbor = current_cell + Vector2i(dx, dy)
					var water_tile = water_layer.get_cell_source_id(neighbor)
					if water_tile != -1:
						return true
	return false


func place_building(cell: Vector2i, size: Vector2i):
	var scene = current_building_data.get("scene")
	var occupancy = current_building_data.get("occupancy", 0)


	if scene == null:
		return

	var instance = scene.instantiate()
	instance.set_meta("building_name", current_building_data.get("name", ""))
	var local_pos = ground_layer.map_to_local(cell)
	instance.global_position = ground_layer.to_global(local_pos)
	add_child(instance)

	buildings[instance] = []

	for x in range(size.x):
		for y in range(size.y):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = current_building_data.get("name", "")
			buildings[instance].append(occupied_cell)

			if current_building_data.get("name") == "Dirt road":
				road_positions[occupied_cell] = "Dirt road"

			if current_building_data.get("name") == "Tree":
				work_spot_cells[occupied_cell] = {
					"type": "tree",
					"max_workers": 1,
					"current_workers": 0
				}					
			
			if current_building_data.get("name") == "Water Workers Hut":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "water",
						"max_workers": 5,
						"current_workers": 0
					}
			
			if current_building_data.get("name") == "Research hut":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "research",
						"max_workers": 5,
						"current_workers": 0
					}
					
			if current_building_data.get("name") == "Berry Picker":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "berry",
						"max_workers": 5,
						"current_workers": 0
					}

			if current_building_data.get("name") == "Wood Cutter":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "wood",
						"max_workers": 5,
						"current_workers": 0
					}
	if current_building_data.get("name") == "Greatfire":
		hud_control.unlock_building_by_name("Small House")
		greatfire_place = true
		call_unassigned_citizens_to_greatfire(cell)

	
	if current_building_data.get("name") == "Small House":
		house_built_count += 1
		houses.append({
			"position": cell,
			"occupancy": occupancy,
			"assigned_citizens": []
		})
		assign_houses_to_citizens()

	if house_built_count == 5:
		hud_control.unlock_building_by_name("Wood Cutter")
		hud_control.unlock_building_by_name("Tree")
		hud_control.unlock_building_by_name("Berry Picker")
		hud_control.unlock_building_by_name("Berry Bush")
		hud_control.unlock_building_by_name("Water Workers Hut")
		hud_control.unlock_building_by_name("Research hut")
		
		
	if occupancy > 0 and main_game != null:
		main_game.increase_max_citizens(occupancy)

		
func call_unassigned_citizens_to_greatfire(greatfire_position: Vector2i):
	for citizen in unassigned_citizens:
		if citizen.has_method("go_to_greatfire"):
			citizen.go_to_greatfire(greatfire_position)


func assign_houses_to_citizens():
	for house in houses:
		var max_occupancy = house["occupancy"]
		while unassigned_citizens.size() > 0 and house["assigned_citizens"].size() < max_occupancy:
			var citizen = unassigned_citizens.pop_front()
			house["assigned_citizens"].append(citizen)
			
			if citizen.has_method("assign_house"):
				citizen.assign_house(house["position"])

	
	
func spawn_citizens(speed_multiplier: float = 1.0):
	print("Spawning a citizen")
	var spawn_cell = Vector2i(-1, -6)
	var spawn_position: Vector2 = ground_layer.to_global(ground_layer.map_to_local(spawn_cell))
	var citizen_instance = citizen_scene.instantiate()
	get_tree().current_scene.add_child(citizen_instance)

	var citizen = citizen_scene.instantiate()

	var offset = Vector2(
		randf_range(0, tile_size.x),
		randf_range(0, tile_size.y)
	)
	citizen.global_position = spawn_position + offset

	citizen.terrain_tilemap = self
	citizen.ground_layer = ground_layer
	citizen.rocks_layer = rocks_layer
	citizen.water_layer = water_layer
	citizen.road_positions = road_positions
	citizen.occupied_cells = occupied_cells
	citizen.work_spot_cells = work_spot_cells
	citizen.citizen_house_position = spawn_cell
	citizen.time_to_live = 300

	citizen.set_speed_multiplier(speed_multiplier)

	add_child(citizen)

	unassigned_citizens.append(citizen)

	assign_houses_to_citizens()

	return citizen


func set_current_building(building_data) -> void:
	current_building_data = building_data
	is_ghost_active = true
	var mouse_pos = get_global_mouse_position()
	ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))

func clear_buildings():
	for child in get_children():
		if child is Node2D and not child.name in ["Ground", "Rocks", "Water"]:
			child.queue_free()

	occupied_cells.clear()
	road_positions.clear()
	work_spot_cells.clear()


func delete_building_at(cell: Vector2i) -> bool:
	if not occupied_cells.has(cell):
		print("❌ No building found at ", cell)
		return false

	var building_instance = occupied_cells[cell]
	if building_instance == null:
		print("❌ No building instance found at ", cell)
		return false

	if not buildings.has(building_instance):
		print("⚠ Building instance not found in buildings dictionary")
		return false

	var occupied_cells_list = buildings[building_instance]

	if building_instance.get_meta("building_name") == "Greatfire":
		print("here")
		greatfire_place = false


	for c in occupied_cells_list:
		occupied_cells.erase(c)
		work_spot_cells.erase(c)
		road_positions.erase(c)

	for i in range(houses.size()):
		if houses[i]["position"] == occupied_cells_list[0]:
			for citizen in houses[i]["assigned_citizens"]:
				unassigned_citizens.append(citizen)
				if citizen.has_method("assign_house"):
					citizen.assign_house(Vector2i.ZERO)

			houses.remove_at(i)
			break

	if is_instance_valid(building_instance):
		building_instance.queue_free()

	buildings.erase(building_instance)

	print("✅ Deleted building at ", cell)

	assign_houses_to_citizens()

	return true




func has_enough_berry_bushes(center: Vector2i) -> bool:
	var count := 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var cell = center + Vector2i(x, y)
			if occupied_cells.has(cell):
				var b = occupied_cells[cell]
				if b.has("type") and b.type == "berry_bush":
					count += 1
	if count >= 5:
		return true
	return false


func place_building_direct(cell: Vector2i, building_data: Dictionary) -> void:
	print("Placing building", building_data.get("name"), "at", cell)
	var size = building_data.get("size", Vector2i(1, 1))
	var scene = building_data.get("scene")
	if scene == null:
		print("⚠ Missing scene for", building_data.get("name"))
		return

	var instance = scene.instantiate()
	var local_pos = ground_layer.map_to_local(cell)
	instance.global_position = ground_layer.to_global(local_pos)
	add_child(instance)

	for x in range(size.x):
		for y in range(size.y):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = building_data.get("name")

			if building_data.get("name") == "Dirt road":
				road_positions[occupied_cell] = "Dirt road"
			
			if building_data.get("name") == "Tree":
				work_spot_cells[occupied_cell] = {
					"type": "tree",
					"max_workers": 1,
					"current_workers": 0
				}
				
			if current_building_data != null and building_data.get("name") == "Berry Picker":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "berry",
						"max_workers": 5,
						"current_workers": 0
					}	
			if current_building_data != null and current_building_data.get("name") == "Water Workers Hut":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "water",
						"max_workers": 5,
						"current_workers": 0
					}
					
			if current_building_data != null and current_building_data.get("name") == "Research hut":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "researh",
						"max_workers": 5,
						"current_workers": 0
					}
					
			if current_building_data != null and current_building_data.get("name") == "Wood Cutter":
				if x == 0 and y == 0:  
					work_spot_cells[occupied_cell] = {
						"type": "wood",
						"max_workers": 5,
						"current_workers": 0
					}

	var occupancy = building_data.get("occupancy", 0)
	if occupancy > 0 and main_game:
		main_game.increase_max_citizens(occupancy)

			
func get_building_data_from_name(name: String) -> Dictionary:
	var all_buildings = {
		"Small House": {
			"name": "Small House",
			"scene": preload("res://scenes/Buildings/Small_House.tscn"),
			"size": Vector2i(2, 2),
			"cost": {"wood": 10},
			"occupancy": 2
		},
		"Dirt road": {
			"name": "Dirt road",
			"scene": preload("res://scenes/Buildings/dirt_road.tscn"),
			"size": Vector2i(1, 1),
			"cost": {}
		},
		"Tree": {
			"name": "Tree",
			"scene": preload("res://scenes/Buildings/Tree.tscn"),
			"size": Vector2i(1, 1),
			"cost": {}
		},
		"Berry Picker": {
			"name": "Berry Picker", 
			"scene": preload("res://scenes/Buildings/BerryPicker.tscn"), 
			"size": Vector2i(2,2),
			"cost": {"wood": 15}
		},
		"Greatfire": {
			"name": "Greatfire",
			"scene": preload("res://scenes/Buildings/GreatFire.tscn"),
			"size": Vector2i(2,2),
			"cost": {}
		},
		"Berry Bush": {
			"name": "Berry Bush",
			"scene": preload("res://scenes/Buildings/BerryBush.tscn"),
			"size": Vector2i(1, 1),
			"cost": {}
		},
		"Wood Cutter": {
			"name": "Wood Cutter",
			"scene": preload("res://scenes/Buildings/WoodCutter.tscn"),
			"size": Vector2i(2, 2),
			"cost": {}
		},
		"Water Workers Hut": {
			"name": "Water Workers Hut",
			"scene": preload("res://scenes/Buildings/WaterWorkersHut.tscn"),
			"size": Vector2i(2, 2),
			"cost": {"wood": 10}
		},
		"Research hut": {
			"name": "researh",
			"scene": preload("res://scenes/Buildings/Research.tscn"),
			"size": Vector2i(2, 2),
			"cost": {"wood": 10}
		}
	}
	return all_buildings.get(name, {})
	
	
#func is_valid_berrypicker_position(cell: Vector2i) -> bool:
#	var nearby_bushes := 0
#	for x in range(-1, 2):
#		for y in range(-1, 2):
#			var check_cell = cell + Vector2i(x, y)
#			if work_spot_cells.has(check_cell) and work_spot_cells[check_cell].name == "BerryBush":
#				nearby_bushes += 1
#
#	return nearby_bushes >= 5
