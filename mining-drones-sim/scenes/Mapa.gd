extends TileMap

enum Cell { UNKNOWN, EXPLORED, GOLD, OBSTACLE }

var w: int = 20
var h: int = 20
var cells: Array = []

@export var gold_ratio: float = 0.01
@export var obstacle_ratio: float = 0.08

func _ready():
	generate_random_map(w, h, gold_ratio, obstacle_ratio)

func generate_random_map(width: int, height: int, p_gold: float, p_obs: float) -> void:
	w = width
	h = height
	cells.clear()
	randomize()
	for y in range(h + 2):
		var row: Array = []
		for x in range(w + 2):
			if y == 0 or y == h + 1 or x == 0 or x == w + 1:
				row.append(Cell.UNKNOWN)
			else:
				var r: float = randf()
				var v: int = Cell.UNKNOWN
				if r < p_obs:
					v = Cell.OBSTACLE
				elif r < p_obs + p_gold:
					v = Cell.GOLD
				row.append(v)
		cells.append(row)
	_redraw()

func _redraw() -> void:
	clear()
	for y in range(h + 2):
		for x in range(w + 2):
			_paint_cell(Vector2i(x - (w + 2) / 2, y - (h + 2) / 2), cells[y][x])

func _paint_cell(c: Vector2i, state: int) -> void:
	var atlas_coords: Vector2i
	match state:
		Cell.UNKNOWN:
			atlas_coords = Vector2i(0, 0)
		Cell.EXPLORED:
			atlas_coords = Vector2i(1, 0)
		Cell.GOLD:
			atlas_coords = Vector2i(2, 0)
		Cell.OBSTACLE:
			atlas_coords = Vector2i(3, 0)
		_:
			atlas_coords = Vector2i(0, 0)

	# layer = 0, source_id = 0, atlas_coords, alternative_tile = 0
	set_cell(0, c, 0, atlas_coords, 0)
