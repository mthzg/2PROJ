extends TileMap



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

var ghost_cell = Vector2i.ZERO
var is_ghost_active = false

var current_building_data = null
var max_citizens = null




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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_ghost_active:
			print("cancel placement")
			is_ghost_active = false
			ghost_cell = null
			current_building_data = null
			self.queue_redraw()
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_ghost_active and ghost_cell != null:
			if try_place_building(ghost_cell):
				is_ghost_active = false
				ghost_cell = null
				current_building_data = null
			self.queue_redraw()
			


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
func try_place_building(cell: Vector2i):
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
				print("Cannot place; blocked at cell ", check_cell)
				return false

			if check_cell in occupied_cells:
				print("Cannot place; occupied at cell ", check_cell)
				return false
	
	# Check resource cost
	var cost = current_building_data.get("cost", {})
	if main_game != null:
		for resource_name in cost.keys():
			var amount = cost[resource_name]
			if resource_name == "wood":
				if not main_game.can_spend_wood(amount):
					print("Not enough wood to place building!")
					return false
			else:
				# Implement other resource checks here if needed
				pass
	
	# If all clear, deduct resources
	if main_game != null:
		for resource_name in cost.keys():
			var amount = cost[resource_name]
			if resource_name == "wood":
				main_game.spend_wood(amount)

	print("✅ Placing building at ", cell)
	place_building(cell, size)
	return true

# Place building by ID, mark cells occupied
func place_building(cell: Vector2i, size: Vector2i):
	var scene = current_building_data.get("scene")
	var occupancy = current_building_data.get("occupancy", 0)

	if scene == null:
		return

	var instance = scene.instantiate()
	var local_pos = ground_layer.map_to_local(cell)
	instance.global_position = ground_layer.to_global(local_pos)
	add_child(instance)

	for x in range(size.x):
		for y in range(size.y):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = current_building_data.get("name")

			if current_building_data.get("name") == "Dirt road":
				road_positions[occupied_cell] = "Dirt road"
			
			if current_building_data.get("name") == "Tree":
				work_spot_cells[occupied_cell] = {
					"type": "tree",
					"max_workers": 1,
					"current_workers": 0
				}

	# Update max citizens on main game script
	if occupancy > 0 and main_game != null:
		main_game.increase_max_citizens(occupancy)




	#place building in a row once one is selected		
	#current_building_data = null
func spawn_citizens(speed_multiplier: float = 1.0):
	var spawn_cell = Vector2i(-1, -6)
	var spawn_position: Vector2 = ground_layer.to_global(ground_layer.map_to_local(spawn_cell))

	var citizen = citizen_scene.instantiate()

	# Optional: slight random offset within tile
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
	return citizen

# Optionally: add a method to change current building selection
func set_current_building(building_data) -> void:
	current_building_data = building_data
	is_ghost_active = true
	var mouse_pos = get_global_mouse_position()
	ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))


func delete_building_at(cell: Vector2i) -> bool:
	if not occupied_cells.has(cell):
		print("❌ No building found at ", cell)
		return false
	
	var building_name = occupied_cells[cell]
	
	# Remove from occupied_cells
	occupied_cells.erase(cell)
	
	# Remove from work_spot_cells if exists
	if work_spot_cells.has(cell):
		work_spot_cells.erase(cell)
	
	# Remove from road_positions if relevant
	if road_positions.has(cell):
		road_positions.erase(cell)
	
	# Find and remove instance node at cell:
	for child in get_children():
		if child.global_position == ground_layer.to_global(ground_layer.map_to_local(cell)):
			child.queue_free()
			break
	
	print("✅ Deleted building ", building_name, " at ", cell)
	return true
