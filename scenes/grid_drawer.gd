extends Node2D

@export var grid_color := Color(0.6, 0.6, 0.6, 0.4)
@export var grid_size := 16
@export var grid_half_width := 100  # number of tiles to left/right from center
@export var grid_half_height := 100 # number of tiles up/down from center

func _draw():
	@warning_ignore("unused_variable")
	var total_width = grid_half_width * 2
	@warning_ignore("unused_variable")
	var total_height = grid_half_height * 2

	for x in range(-grid_half_width, grid_half_width + 1):
		var x_pos = x * grid_size
		draw_line(Vector2(x_pos, -grid_half_height * grid_size), Vector2(x_pos, grid_half_height * grid_size), grid_color)

	for y in range(-grid_half_height, grid_half_height + 1):
		var y_pos = y * grid_size
		draw_line(Vector2(-grid_half_width * grid_size, y_pos), Vector2(grid_half_width * grid_size, y_pos), grid_color)
