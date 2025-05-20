extends CharacterBody2D

var terrain_tilemap: TileMap  # Parent TileMap that owns the layers
var ground_layer: TileMapLayer
var rocks_layer: TileMapLayer
var water_layer: TileMapLayer
var road_positions: Dictionary 
var occupied_cells: Dictionary 
var work_spot_cells: Dictionary
var citizen_house_position: Vector2i

@export var speed: float = 50.0

# Internal pathfinding state
var path: Array[Vector2i] = []
var path_index := 0

func _ready():
	if terrain_tilemap == null:
		push_error("❌ terrain_tilemap is not set!")
		return

	velocity = Vector2.RIGHT * speed
	print("✅ Citizen ready with velocity: ", velocity)

func _physics_process(delta):
	if terrain_tilemap == null:
		return

	var local_pos = terrain_tilemap.to_local(global_position)
	var cell = terrain_tilemap.local_to_map(local_pos)

	# Follow path if available
	if path.size() > 0:
		move_along_path(delta)
		return

	# Default idle movement logic
	if is_over_water(cell):
		velocity = Vector2.ZERO
	elif is_on_road(cell):
		velocity = Vector2.RIGHT * speed
	elif occupied_cells.has(cell):
		velocity = Vector2.RIGHT * speed  # ✅ Can walk on buildings
	else:
		velocity = Vector2.ZERO

	move_and_slide()


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

	var nearest: Vector2i = Vector2i.ZERO
	var found := false
	var min_distance := INF

	for target_cell in work_spot_cells.keys():
		if work_spot_cells[target_cell] == resource_type:
			var dist = start_cell.distance_to(target_cell)
			if dist < min_distance:
				min_distance = dist
				nearest = target_cell
				found = true

	if nearest == null:
		print("❌ No available resource spot of type: ", resource_type)
		return

	print("🎯 Going to gather ", resource_type, " at ", nearest)
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
	return road_positions.has(cell) or occupied_cells.has(cell)


func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var total_path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		total_path.insert(0, current)
	return total_path


func move_along_path(delta):
	if path_index >= path.size():
		velocity = Vector2.ZERO
		return

	var target_cell = path[path_index]
	var target_pos = terrain_tilemap.to_global(terrain_tilemap.map_to_local(target_cell))
	var direction = (target_pos - global_position).normalized()

	velocity = direction * speed
	move_and_slide()

	if global_position.distance_to(target_pos) < 4.0:
		path_index += 1
