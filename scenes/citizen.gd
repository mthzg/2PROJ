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

var main_game: Node = null  # Reference to main script to call increment_wood()

var path: Array[Vector2i] = []
var path_index := 0
var gather_target: Vector2i = Vector2i.ZERO
var is_gathering: bool = false
var is_returning_home: bool = false
var has_gathered_resource: bool = false

var current_ressource_type_to_gather: String

var work_hours_elapsed: int = 0
var is_sleeping: bool = false
var sleep_timer: int = 0
var previous_resource_type: String = ""

var house_position: Vector2i = Vector2i.ZERO  # default, not null

var hunger: float = 1.0
var thirst: float = 1.0
var sleep: float = 1.0
var berries: float = 1.0
var birth_time: float = 0.0  # Use OS.get_unix_time() when spawned, or in-game time

func assign_house(house_pos: Vector2i):
	house_position = house_pos
	print("Citizen assigned to house at: ", house_pos)
	go_home()
	# If not already working or returning home, start gathering
	#if not is_gathering and not is_returning_home and !has_gathered_resource:
	#	go_gather("tree")

func cleanup_before_removal():
	# Remove from house
	if house_position != Vector2i.ZERO:
		for house in terrain_tilemap.houses:
			if house.has("position") and house["position"] == house_position:
				if house.has("assigned_citizens"):
					house["assigned_citizens"] = house["assigned_citizens"].filter(func(c): return c != self)
					print("Citizen removed from house at", house_position)
				break

	# Decrement work spot workers if needed
	if gather_target != Vector2i.ZERO and gather_target in work_spot_cells:
		work_spot_cells[gather_target].current_workers = max(0, work_spot_cells[gather_target].current_workers - 1)
		print("Decremented worker count at: ", gather_target)

	# Reset all
	house_position = Vector2i.ZERO
	gather_target = Vector2i.ZERO
	is_gathering = false
	is_returning_home = false
	path.clear()
	path_index = 0

	# Reassign
	if terrain_tilemap and terrain_tilemap.has_method("assign_houses_to_citizens"):
		terrain_tilemap.assign_houses_to_citizens()






# Getter function to access the private variable
func get_speed_multiplier() -> float:
	return _speed_multiplier

func _physics_process(delta):
	if terrain_tilemap == null:
		return

	var direction = get_movement_direction()
	velocity = direction * speed * _speed_multiplier
	move_and_slide()

func set_speed_multiplier(multiplier: float) -> void:
	_speed_multiplier = multiplier

func refresh_velocity():
	var direction = get_movement_direction()
	velocity = direction * speed * _speed_multiplier

func get_movement_direction() -> Vector2:
	# Prioritize path-following
	if path.size() > 0 and path_index < path.size():
		var target_cell = path[path_index]
		var target_pos = terrain_tilemap.to_global(terrain_tilemap.map_to_local(target_cell))
		var dir = (target_pos - global_position).normalized()

		# Close enough to target tile, advance to next step
		if global_position.distance_to(target_pos) < 4.0:
			path_index += 1

			# Reached final destination
			if path_index >= path.size():
				if is_returning_home:
					is_returning_home = false

					# Only give resource after returning home
					if has_gathered_resource:
						has_gathered_resource = false
						if main_game and main_game.has_method("increment_wood"):
							main_game.increment_wood(1)

					## Start another task if needed
					#go_gather("tree")

				elif not is_gathering:
					start_gathering()

		return dir

	# Idle fallback behavior
	var local_pos = terrain_tilemap.to_local(global_position)
	var cell = terrain_tilemap.local_to_map(local_pos)

	if is_over_water(cell):
		return Vector2.ZERO
	elif is_on_road(cell) or occupied_cells.has(cell):
		return Vector2.ZERO
	else:
		return Vector2.ZERO


func is_on_road(cell: Vector2i) -> bool:
	return road_positions.has(cell)

func is_over_water(cell: Vector2i) -> bool:
	var ground_tile = ground_layer.get_cell_source_id(cell)
	var rocks_tile = rocks_layer.get_cell_source_id(cell)
	var water_tile = water_layer.get_cell_source_id(cell)
	return water_tile != -1 or (ground_tile == -1 and rocks_tile == -1)

func stop_gathering():
	if gather_target != Vector2i.ZERO and gather_target in work_spot_cells:
		work_spot_cells[gather_target].current_workers -= 1
	gather_target = Vector2i.ZERO
	is_gathering = false
	path.clear()
	path_index = 0
	go_home()


func go_gather(resource_type: String) -> bool:
	if house_position == Vector2i.ZERO:
		print("Citizen cannot work without a home.")
		return false
	if is_gathering or gather_target != Vector2i.ZERO:
		print("Already gathering, skipping duplicate call")
		return false
	var local_pos = terrain_tilemap.to_local(global_position)
	var start_cell = terrain_tilemap.local_to_map(local_pos)

	var nearest := Vector2i.ZERO
	var found := false
	var min_distance := INF

	for target_cell in work_spot_cells.keys():
		var data = work_spot_cells[target_cell]
		if (data.type == resource_type and data.current_workers < data.max_workers):
			var dist = start_cell.distance_to(target_cell)
			if dist < min_distance:
				min_distance = dist
				nearest = target_cell
				found = true

	if not found:
		return false

	current_ressource_type_to_gather = resource_type
	work_spot_cells[nearest].current_workers += 1
	gather_target = nearest
	path = find_path(start_cell, nearest)
	path_index = 0
	return true



	
	
func start_gathering():
	is_gathering = true
	if current_ressource_type_to_gather == "tree":
		var gather_time = 5.0 / _speed_multiplier
		var elapsed := 0.0
		if work_spot_cells.has(gather_target):
			work_spot_cells[gather_target]["cut_progress"] = 0.0
		while elapsed < gather_time:
			await get_tree().process_frame
			var dt = get_process_delta_time()
			elapsed += dt
			if work_spot_cells.has(gather_target):
				work_spot_cells[gather_target]["cut_progress"] = clamp(elapsed / gather_time, 0.0, 1.0)
		if work_spot_cells.has(gather_target):
			work_spot_cells[gather_target]["cut_progress"] = 1.0
		if terrain_tilemap and terrain_tilemap.has_method("delete_building_at"):
			terrain_tilemap.delete_building_at(gather_target)
		is_gathering = false
		has_gathered_resource = true
		stop_gathering()

func go_home():
	if house_position == Vector2i.ZERO:
		return

	is_returning_home = true
	var local_pos = terrain_tilemap.to_local(global_position)
	var start_cell = terrain_tilemap.local_to_map(local_pos)
	path = find_path(start_cell, house_position)
	path_index = 0

func go_to_greatfire(position: Vector2i):
	is_gathering = false
	is_returning_home = false
	var local_pos = terrain_tilemap.to_local(global_position)
	var start_cell = terrain_tilemap.local_to_map(local_pos)
	path = find_path(start_cell, position)
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
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if main_game and main_game.has_method("show_citizen_popup"):
			main_game.show_citizen_popup(self)
			
func increment_time_to_live(counter: int):
	if counter == 1:
		time_to_live += 5
	elif counter == 2:
		time_to_live += 10
	
	

func get_age_seconds() -> int:
	return int(Time.get_unix_time_from_system() - birth_time)
