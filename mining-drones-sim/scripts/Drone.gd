extends Node2D

@onready var map = get_parent().get_node("TileMap (Mapa)")
var grid_pos = Vector2i(0, 0)
var timer: Timer

func _ready():
	position = Vector2(grid_pos.x * 32, grid_pos.y * 32)
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()
	explore_current()

func _draw():
	draw_circle(Vector2(0, 0), 10, Color.BLUE)

func _on_timer_timeout():
	move_to_next()

func move_to_next():
	var directions = [
		Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	directions.shuffle()
	for dir in directions:
		var new_grid = grid_pos + dir
		if abs(new_grid.x) <= 9 and abs(new_grid.y) <= 9:
			var cell_x = new_grid.x + 11
			var cell_y = new_grid.y + 11
			if map.cells[cell_y][cell_x] == map.Cell.UNKNOWN:
				grid_pos = new_grid
				position = Vector2(grid_pos.x * 32, grid_pos.y * 32)
				explore_current()
				return

func explore_current():
	var cell_x = grid_pos.x + 11
	var cell_y = grid_pos.y + 11
	map.cells[cell_y][cell_x] = map.Cell.EXPLORED
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var adj_x = cell_x + dx
			var adj_y = cell_y + dy
			if adj_x >= 0 and adj_x < map.cells[0].size() and adj_y >= 0 and adj_y < map.cells.size():
				if map.cells[adj_y][adj_x] == map.Cell.GOLD:
					print("ore found")
	map._redraw()
