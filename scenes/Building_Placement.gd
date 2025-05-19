extends TileMap

@onready var ground_layer := get_node("Ground")
@onready var rocks_layer := get_node("Rocks")
@onready var water_layer := get_node("Water")

var tile_size: Vector2 = Vector2(16, 16)
var occupied_cells := {}

var ghost_cell = Vector2i.ZERO
var is_ghost_active = false

var current_building_data = null

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
		return

	var size = current_building_data.get("size", Vector2i(1, 1))

	for x in range(size.x):
		for y in range(size.y):
			var check_cell = cell + Vector2i(x, y)

			var ground_tile = ground_layer.get_cell_source_id(check_cell)
			var rocks_tile = rocks_layer.get_cell_source_id(check_cell)
			var water_tile = water_layer.get_cell_source_id(check_cell)

			if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
				print("Cannot place; blocked at cell ", check_cell)
				return

			if check_cell in occupied_cells:
				print("Cannot place; occupied at cell ", check_cell)
				return

	print("✅ Placing building at ", cell)
	place_building(cell, size)

# Place building by ID, mark cells occupied
func place_building(cell: Vector2i, size: Vector2i):
	var scene = current_building_data.get("scene")
	if scene == null:
		return

	var instance = scene.instantiate()
	var local_pos = ground_layer.map_to_local(cell)
	instance.global_position = ground_layer.to_global(local_pos)
	add_child(instance)

	for x in range(size.x):
		for y in range(size.y):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = true
			
	#place building in a row once one is selected		
	#current_building_data = null


# Optionally: add a method to change current building selection
func set_current_building(building_data) -> void:
	current_building_data = building_data
	is_ghost_active = true
	var mouse_pos = get_global_mouse_position()
	ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))
