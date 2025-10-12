extends TileMap

enum Cell { UNKNOWN, EXPLORED, GOLD, OBSTACLE, CONTROL_CENTER }

var w: int = 20
var h: int = 20
var cells: Array = []

@export var gold_ratio: float = 0.01
@export var obstacle_ratio: float = 0.08
@export var control_center_pos: Vector2i = Vector2i(-12, -12)

func _ready():
	generate_random_map(w, h, gold_ratio, obstacle_ratio)

func generate_random_map(width: int, height: int, p_gold: float, p_obs: float) -> void:
	w = width
	h = height
	cells.clear()
	randomize()
	for y in range(h + 4):
		var row: Array = []
		for x in range(w + 4):
			if y == 0 or y == h + 3 or x == 0 or x == w + 3:
				row.append(Cell.OBSTACLE)
			elif y == 1 or y == h + 2 or x == 1 or x == w + 2:
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
	var offset: int = int((w + 4) / 2)
	var idx_y: int = offset + control_center_pos.y
	var idx_x: int = offset + control_center_pos.x
	if idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4:
		cells[idx_y][idx_x] = Cell.CONTROL_CENTER
	_redraw()

func _redraw() -> void:
	clear()
	for y in range(h + 4):
		for x in range(w + 4):
			_paint_cell(Vector2i(x - int((w + 4) / 2), y - int((h + 4) / 2)), cells[y][x])

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
		Cell.CONTROL_CENTER:
			atlas_coords = Vector2i(4, 0)
		_:
			atlas_coords = Vector2i(0, 0)

	# layer = 0, source_id = 0, atlas_coords, alternative_tile = 0
	set_cell(0, c, 0, atlas_coords, 0)

func get_state_centered(c: Vector2i) -> int:
	var offset: int = int((w + 4) / 2)
	var idx_y = offset + c.y
	var idx_x = offset + c.x
	if idx_y < 0 or idx_y >= h + 4 or idx_x < 0 or idx_x >= w + 4:
		return Cell.UNKNOWN
	return cells[idx_y][idx_x]

func set_state_centered(c: Vector2i, state: int) -> void:
	var offset: int = int((w + 4) / 2)
	var idx_y = offset + c.y
	var idx_x = offset + c.x
	if idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4:
		cells[idx_y][idx_x] = state
		_paint_cell(Vector2i(idx_x - offset, idx_y - offset), state)

func in_bounds_centered(c: Vector2i) -> bool:
	var offset: int = int((w + 4) / 2)
	var idx_y = offset + c.y
	var idx_x = offset + c.x
	return idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4

# --- Helpers para trabajar en coords de grilla "centradas" (como en _redraw) ---

func grid_size() -> Vector2i:
	return Vector2i(w + 2, h + 2)

func grid_half() -> Vector2i:
	# Desplazamiento usado en _redraw: (x - (w+2)/2, y - (h+2)/2)
	return Vector2i(int((w + 2) / 2), int((h + 2) / 2))

func to_index_coords(c: Vector2i) -> Vector2i:
	# Convierte celda centrada -> índice en 'cells'
	# c=(0,0) (centro) se vuelve (half, half)
	return c + grid_half()

func cell_to_local(c: Vector2i) -> Vector2:
	# Posición local del centro de esa celda en el TileMap
	return map_to_local(c)
