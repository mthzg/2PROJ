extends TileMap

@onready var ground_layer := get_node("Ground")
@onready var rocks_layer := get_node("Rocks")
@onready var water_layer := get_node("Water")

var tile_size: Vector2 = Vector2(16, 16)
var occupied_cells := {}

var ghost_cell = Vector2i.ZERO
var is_ghost_active = false

# Dictionary mapping building IDs to their PackedScenes
var buildings = {
	1: preload("res://scenes/Buildings/Small_House.tscn"),
	2: preload("res://scenes/Buildings/Tree.tscn"),
	3: preload("res://scenes/Buildings/GreatFire.tscn")
}

# Current building ID to place; default to 1 (Small House)
var current_building_id = null



func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_ghost_active and ghost_cell != null:
			if try_place_building_2x2(ghost_cell, current_building_id):
				is_ghost_active = false
				ghost_cell = null
				current_building_id = null
			self.queue_redraw()
		else:
			if not current_building_id:
				print("Error: no building id set")
				return
			is_ghost_active = true
			var mouse_pos = get_global_mouse_position()
			ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))
			self.queue_redraw()

func _process(_delta):
	if is_ghost_active:
		var mouse_pos = get_global_mouse_position()
		ghost_cell = ground_layer.local_to_map(ground_layer.to_local(mouse_pos))
		self.queue_redraw()

func _draw():
	if is_ghost_active and ghost_cell != null:
		for x in range(2):
			for y in range(2):
				var offset = Vector2(x, y) * tile_size
				var pos = (Vector2(ghost_cell.x, ghost_cell.y) * tile_size) + offset
				draw_rect(Rect2(pos, tile_size), Color(0.2, 0.4, 1.0, 0.3), true)

# Try place building with ID parameter, returns true if placement succeeded
func try_place_building_2x2(cell: Vector2i, building_id: int) -> bool:
	# Check tiles for placement
	for x in range(2):
		for y in range(2):
			var check_cell = cell + Vector2i(x, y)

			var ground_tile = ground_layer.get_cell_source_id(check_cell)
			var rocks_tile = rocks_layer.get_cell_source_id(check_cell)
			var water_tile = water_layer.get_cell_source_id(check_cell)

			if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
				print("Cannot place building here; blocked at cell ", check_cell)
				return false

			if check_cell in occupied_cells:
				print("Cannot place building here; already occupied at cell ", check_cell)
				return false

	print("Placing building ID ", building_id, " at cell ", cell)
	place_building(cell, building_id)
	return true

# Place building by ID, mark cells occupied
func place_building(cell: Vector2i, building_id: int) -> void:
	if not buildings.has(building_id):
		print("Error: Unknown building ID ", building_id)
		return

	var building_scene = buildings[building_id]
	var building_instance = building_scene.instantiate()

	var local_pos = ground_layer.map_to_local(cell)
	building_instance.global_position = ground_layer.to_global(local_pos)
	add_child(building_instance)

	for x in range(2):
		for y in range(2):
			var occupied_cell = cell + Vector2i(x, y)
			occupied_cells[occupied_cell] = true

# Optionally: add a method to change current building selection
func set_current_building(building_id: int) -> void:
	if buildings.has(building_id):
		current_building_id = building_id
	else:
		print("Building ID ", building_id, " not found")
