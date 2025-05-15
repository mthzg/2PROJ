extends Node2D

@export var grid_size := 32
@export var grid_width := 40
@export var grid_height := 30
@export var grid_color := Color(0.6, 0.6, 0.6, 0.4)

func _draw():
	for x in range(grid_width + 1):
		draw_line(Vector2(x * grid_size, 0), Vector2(x * grid_size, grid_height * grid_size), grid_color)
	for y in range(grid_height + 1):
		draw_line(Vector2(0, y * grid_size), Vector2(grid_width * grid_size, y * grid_size), grid_color)
