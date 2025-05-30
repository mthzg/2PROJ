extends Node2D

@onready var tilemap = get_node("../Terrain")
@export var color: Color = Color(0, 0, 0, 1.0)  # Solid black

@export var map_width: int = 100
@export var map_height: int = 100

func _draw():
	if not tilemap:
		print("test not found")
		return

	var cell_size = tilemap.tile_set.tile_size  # Vector2i
	var map_size = Vector2i(map_width, map_height)

	# Convert cell_size and map_size to Vector2 for multiplication
	var total_size = Vector2(cell_size) * Vector2(map_size)
	var offset = -total_size / 2.0

	for x in range(map_size.x):
		for y in range(map_size.y):
			var cell = Vector2i(x, y)
			var center_pos = tilemap.map_to_local(cell)
			var pos = offset + center_pos - Vector2(cell_size) / 2.0
			draw_rect(Rect2(pos, Vector2(cell_size)), color, false)
