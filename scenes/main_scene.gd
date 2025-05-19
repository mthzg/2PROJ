extends Node2D

#@onready var terrain := $Terrain
#@onready var ground_layer := terrain.get_node("Ground")
#@onready var rocks_layer := terrain.get_node("Rocks")
#@onready var water_layer := terrain.get_node("Water")
#
#@onready var house_scene := preload("res://House.tscn")
#
#var occupied_cells := {}  # Dictionary with keys Vector2i, values = true if occupied
#
#
#func _input(event):
#	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
#		var global_mouse_pos = get_global_mouse_position()
#		try_place_house(global_mouse_pos)
#
#
#func try_place_house(global_pos: Vector2):
#	var local_pos = ground_layer.to_local(global_pos)
#	var cell = ground_layer.local_to_map(local_pos)
#
#	# Check all tiles in 4x4 area starting at 'cell'
#	for x in range(2):
#		for y in range(2):
#			var check_cell = cell + Vector2i(x, y)
#
#			var ground_tile = ground_layer.get_cell_source_id(check_cell)
#			var rocks_tile = rocks_layer.get_cell_source_id(check_cell)
#			var water_tile = water_layer.get_cell_source_id(check_cell)
#
#			# Check terrain suitability
#			if ground_tile == -1 or rocks_tile != -1 or water_tile != -1:
#				print("Cannot place house here; blocked at cell ", check_cell)
#				return
#
#			# Check if cell is already occupied by another house
#			if check_cell in occupied_cells:
#				print("Cannot place house here; already occupied at cell ", check_cell)
#				return
#
#	print("Placing house at cell ", cell)
#	place_house(cell)
#
#
#
#func place_house(cell: Vector2i):
#	var house_instance = house_scene.instantiate()
#	
#	# Convert tile coords to world position
#	var local_pos = ground_layer.map_to_local(cell)
#	house_instance.global_position = ground_layer.to_global(local_pos)
#
#	add_child(house_instance)
#
#	# Mark the 4x4 area as occupied
#	for x in range(2):
#		for y in range(2):
#			var occupied_cell = cell + Vector2i(x, y)
#			occupied_cells[occupied_cell] = true
#
