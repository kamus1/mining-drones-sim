extends Node2D

@export var cell_size: int = 32
@export var width: int = 22
@export var height: int = 22
@export var line_color: Color = Color.BLACK
@export var line_width: float = 1.0

func _draw():
	for x in range(width + 1):
		var start = Vector2(x * cell_size, 0)
		var end = Vector2(x * cell_size, height * cell_size)
		draw_line(start, end, line_color, line_width)
	for y in range(height + 1):
		var start = Vector2(0, y * cell_size)
		var end = Vector2(width * cell_size, y * cell_size)
		draw_line(start, end, line_color, line_width)
