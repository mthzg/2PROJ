extends TileMap

signal building_selected(cell: Vector2i, building_data: Dictionary)

@onready var ground_layer := get_node("Ground")
@onready var rocks_layer := get_node("Rocks")
@onready var water_layer := get_node("Water")
var citizen_scene := preload("res://scenes/Buildings/Citizen.tscn")

var main_game  # reference to main script (set from main)
var tile_size: Vector2 = Vector2(16, 16)
var occupied_cells = {}
var road_positions: = {}
var work_spot_cells = {}
var citizen_house_position: Vector2i
var buildings = {}  # Dictionary: building_instance -> array of Vector2i cells it occupies


var ghost_cell = Vector2i.ZERO
var is_ghost_active = false

var current_building_data = null
var max_citizens = null

var house_built_count = 0
var free_house_limit = 5

var houses = []  # List to track houses with their data (position, occupancy, assigned citizens)
var unassigned_citizens = []  # Citizens waiting for house assignment




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

	while placed < 30:
		var rand_x = randi() % map_bounds.size.x + map_bounds.position.x
		var rand_y = randi() % map_bounds.size.y + map_bounds.position.y
		var cell = Vector2i(rand_x, rand_y)

		# Check if cell is free and valid
		if occupied_cells.has(cell):
			continue
		
		var ground_tile = ground_layer.get_cell_source_id(cell)
		var rocks_tile = rocks_layer.get_cell_source_id(cell)
		var water_tile = water_layer.get_cell_source_id(cell)
		if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
			continue

		# Directly place the tree building here
		var tree_scene = preload("res://scenes/Buildings/Tree.tscn")
		var instance = tree_scene.instantiate()
		var local_pos = ground_layer.map_to_local(cell)
		instance.global_position = ground_layer.to_global(local_pos)
		add_child(instance)

		# Mark cell occupied and work spot for wood
		occupied_cells[cell] = "Tree"
		work_spot_cells[cell] = {
			"type": "tree",
			"max_workers": 1,
			"current_workers": 0,
			"is_startup": true  # <<< THIS is the key
		}
		

		placed += 1

# Call this in _ready
func _ready():
	spawn_30_trees()
	


func _input(event):
	# Cancel placement with right click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_ghost_active:
			print("cancel placement")
			is_ghost_active = false
			ghost_cell = null
			current_building_data = null
			self.queue_redraw()
		return  # Prevents further processing for this event

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
				return  # Don't try placement
		elif not is_ghost_active:
			# Select building if one is under the cursor
			if occupied_cells.has(clicked_cell):
				var building_name = occupied_cells[clicked_cell]
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

# Try place building with ID parameter, returns true if placement succeeded
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

	# Copy cost so we can modify it safely
	var base_cost = current_building_data.get("cost", {})
	var cost = base_cost.duplicate(true)  # Deep copy to avoid mutating original data


	# Apply "first 5 houses free" rule
	if current_building_data.get("name") == "Small House" and house_built_count < free_house_limit:
		cost["wood"] = 0

	# Check resources
	if main_game != null:
		for resource_name in cost.keys():
			var amount = cost[resource_name]
			if resource_name == "wood":
				if not main_game.can_spend_wood(amount):
					print("❌ Not enough wood to place building!")
					return false
			else:
				# You can add other resource checks here if needed
				pass

	# Deduct resources
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


func place_building(cell: Vector2i, size: Vector2i):
	var scene = current_building_data.get("scene")
	var occupancy = current_building_data.get("occupancy", 0)

	if scene == null:
		return

	var instance = scene.instantiate()
	var local_pos = ground_layer.map_to_local(cell)
	instance.global_position = ground_layer.to_global(local_pos)
	add_child(instance)

	# Track the instance and its occupied cells
	buildings[instance] = []

	for x in range(size.x):
		for y in range(size.y):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = instance
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

	if current_building_data.get("name") == "Small House":
		house_built_count += 1
		houses.append({
			"position": cell,
			"occupancy": occupancy,
			"assigned_citizens": []
		})
		assign_houses_to_citizens()

	if occupancy > 0 and main_game != null:
		main_game.increase_max_citizens(occupancy)

		


func assign_houses_to_citizens():
	for house in houses:
		var max_occupancy = house["occupancy"]
		while unassigned_citizens.size() > 0 and house["assigned_citizens"].size() < max_occupancy:
			var citizen = unassigned_citizens.pop_front()
			house["assigned_citizens"].append(citizen)
			
			# Assign house position to citizen
			if citizen.has_method("assign_house"):
				citizen.assign_house(house["position"])

	
	
func spawn_citizens(speed_multiplier: float = 1.0):
	var spawn_cell = Vector2i(-1, -6)
	var spawn_position: Vector2 = ground_layer.to_global(ground_layer.map_to_local(spawn_cell))

	var citizen = citizen_scene.instantiate()

	var offset = Vector2(
		randf_range(0, tile_size.x),
		randf_range(0, tile_size.y)
	)
	citizen.global_position = spawn_position + offset

	# Assign tilemaps and layers
	citizen.terrain_tilemap = self
	citizen.ground_layer = ground_layer
	citizen.rocks_layer = rocks_layer
	citizen.water_layer = water_layer
	citizen.road_positions = road_positions
	citizen.occupied_cells = occupied_cells
	citizen.work_spot_cells = work_spot_cells
	citizen.citizen_house_position = spawn_cell
	citizen.time_to_live = 300

	# Apply speed multiplier
	citizen.set_speed_multiplier(speed_multiplier)

	add_child(citizen)

	# Add citizen to unassigned list for house assignment
	unassigned_citizens.append(citizen)

	# Try assign house immediately in case a house exists
	assign_houses_to_citizens()

	return citizen


# Optionally: add a method to change current building selection
func set_current_building(building_data) -> void:
	current_building_data = building_data
	is_ghost_active = true
	var mouse_pos = get_global_mouse_position()
	ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))

func clear_buildings():
	for child in get_children():
		# Optionally skip non-building nodes like layers if needed
		if child is Node2D and not child.name in ["Ground", "Rocks", "Water"]:
			child.queue_free()

	# Clear internal tracking dictionaries
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

	# Remove occupied cells, work spots, road positions
	for c in occupied_cells_list:
		occupied_cells.erase(c)
		work_spot_cells.erase(c)
		road_positions.erase(c)

	# Find the house that corresponds to this building's main cell (usually the first occupied cell)
	for i in range(houses.size()):
		if houses[i]["position"] == occupied_cells_list[0]:
			# Unassign citizens from this house
			for citizen in houses[i]["assigned_citizens"]:
				# Add citizen back to unassigned list
				unassigned_citizens.append(citizen)

				# Also, clear the citizen's assigned house property if applicable
				if citizen.has_method("assign_house"):
					citizen.assign_house(Vector2i.ZERO)

			houses.remove_at(i)
			break

	# Remove the building node
	if is_instance_valid(building_instance):
		building_instance.queue_free()

	# Remove from buildings dictionary
	buildings.erase(building_instance)

	print("✅ Deleted building at ", cell)

	# Optionally, try re-assigning houses to citizens
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
				
			if building_data.get("name") == "Berry Picker":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "berry",
						"max_workers": 5,
						"current_workers": 0
					}	
			if current_building_data.get("name") == "Water Workers Hut":
				if x == 0 and y == 0:
					work_spot_cells[occupied_cell] = {
						"type": "water",
						"max_workers": 5,
						"current_workers": 0
					}
			if current_building_data.get("name") == "Wood Cutter":
				if x == 0 and y == 0:  # only one cell gets the work spot
					work_spot_cells[occupied_cell] = {
						"type": "wood",
						"max_workers": 5,
						"current_workers": 0
					}

	# Apply occupancy if needed
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
