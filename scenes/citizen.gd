extends CharacterBody2D

var terrain_tilemap: TileMap
var ground_layer: TileMapLayer
var rocks_layer: TileMapLayer
var water_layer: TileMapLayer
var road_positions: Dictionary 
var occupied_cells: Dictionary 
var work_spot_cells: Dictionary
var citizen_house_position: Vector2i
var time_to_live: int

var speed: float = 50
var _speed_multiplier: float = 1.0

# Getter function to access the private variable
func get_speed_multiplier() -> float:
	return _speed_multiplier

var path: Array[Vector2i] = []
var path_index := 0

func _physics_process(delta):
	if terrain_tilemap == null:
		return

	var direction = get_movement_direction()
	
	# Directly use _speed_multiplier without intermediate variable
	velocity = direction * speed * _speed_multiplier
	
	move_and_slide()

func set_speed_multiplier(multiplier: float) -> void:
	_speed_multiplier = multiplier
	print("🚀 Speed multiplier set to: ", _speed_multiplier)

func refresh_velocity():
	var direction = get_movement_direction()
	velocity = direction * speed * _speed_multiplier


func get_movement_direction() -> Vector2:
	# Prioritize path-following
	if path.size() > 0 and path_index < path.size():
		var target_cell = path[path_index]
		var target_pos = terrain_tilemap.to_global(terrain_tilemap.map_to_local(target_cell))
		var dir = (target_pos - global_position).normalized()

		if global_position.distance_to(target_pos) < 4.0:
			path_index += 1

		return dir

	# Idle behavior
	var local_pos = terrain_tilemap.to_local(global_position)
	var cell = terrain_tilemap.local_to_map(local_pos)

	if is_over_water(cell):
		return Vector2.ZERO
	elif is_on_road(cell) or occupied_cells.has(cell):
		return Vector2.RIGHT
	else:
		return Vector2.ZERO


	

func is_on_road(cell: Vector2i) -> bool:
	return road_positions.has(cell)

func is_over_water(cell: Vector2i) -> bool:
	var ground_tile = ground_layer.get_cell_source_id(cell)
	var rocks_tile = rocks_layer.get_cell_source_id(cell)
	var water_tile = water_layer.get_cell_source_id(cell)
	return water_tile != -1 or (ground_tile == -1 and rocks_tile == -1)

func go_gather(resource_type: String) -> void:
	var local_pos = terrain_tilemap.to_local(global_position)
	var start_cell = terrain_tilemap.local_to_map(local_pos)

	var nearest := Vector2i.ZERO
	var found := false
	var min_distance := INF

	for target_cell in work_spot_cells.keys():
		var data = work_spot_cells[target_cell]
		if data.type == resource_type and data.current_workers < data.max_workers:
			var dist = start_cell.distance_to(target_cell)
			if dist < min_distance:
				min_distance = dist
				nearest = target_cell
				found = true

	if not found:
		print("❌ No available resource spot of type: ", resource_type)
		return

	print("🎯 Going to gather ", resource_type, " at ", nearest)
	work_spot_cells[nearest].current_workers += 1
	path = find_path(start_cell, nearest)
	path_index = 0

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: start.distance_to(goal)}

	while open_set.size() > 0:
		open_set.sort_custom(func(a, b): return f_score.get(a, INF) < f_score.get(b, INF))
		var current = open_set.pop_front()

		if current == goal:
			return reconstruct_path(came_from, current)

		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = current + offset
			if is_valid_tile(neighbor):
				var tentative_g = g_score.get(current, INF) + 1
				if tentative_g < g_score.get(neighbor, INF):
					came_from[neighbor] = current
					g_score[neighbor] = tentative_g
					f_score[neighbor] = tentative_g + neighbor.distance_to(goal)
					if neighbor not in open_set:
						open_set.append(neighbor)

	return []

func is_valid_tile(cell: Vector2i) -> bool:
	if is_over_water(cell):
		return false

	var ground_tile = ground_layer.get_cell_source_id(cell)
	var rocks_tile = rocks_layer.get_cell_source_id(cell)
	var water_tile = water_layer.get_cell_source_id(cell)

	if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
		return false

	return true

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var total_path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		total_path.insert(0, current)
	return total_path
