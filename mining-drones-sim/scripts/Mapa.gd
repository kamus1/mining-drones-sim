extends TileMap

signal map_config_updated

enum Cell {
	UNKNOWN,
	EXPLORED,
	GOLD,
	SILVER,
	COPPER,
	OBSTACLE,
	CONTROL_CENTER,
	CONTROL_CENTER_GOLD,
	CONTROL_CENTER_SILVER,
	CONTROL_CENTER_COPPER
}

@export var w: int = 20
@export var h: int = 20
var cells: Array = []

@export var gold_ratio: float = 0.01
@export var silver_ratio: float = 0.02
@export var copper_ratio: float = 0.04
@export var obstacle_ratio: float = 0.08
@export var control_center_pos: Vector2i = Vector2i(-12, -12)

func _ready():
	generate_random_map(w, h)

func generate_random_map(width: int, height: int, p_gold: float = gold_ratio, p_silver: float = silver_ratio, p_copper: float = copper_ratio, p_obs: float = obstacle_ratio) -> void:
	w = width
	h = height
	cells.clear()
	randomize()
	for y in range(h + 4):
		var row: Array = []
		for x in range(w + 4):
			var state := Cell.UNKNOWN
			if y == 0 or y == h + 3 or x == 0 or x == w + 3:
				state = Cell.OBSTACLE
			elif y == 1 or y == h + 2 or x == 1 or x == w + 2:
				state = Cell.UNKNOWN
			else:
				var r := randf()
				if r < p_obs:
					state = Cell.OBSTACLE
				else:
					var ore_roll := r - p_obs
					if ore_roll < p_gold:
						state = Cell.GOLD
					elif ore_roll < p_gold + p_silver:
						state = Cell.SILVER
					elif ore_roll < p_gold + p_silver + p_copper:
						state = Cell.COPPER
			row.append(state)
		cells.append(row)
	var offset := int((w + 4) * 0.5)
	var idx_y := offset + control_center_pos.y
	var idx_x := offset + control_center_pos.x
	if idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4:
		cells[idx_y][idx_x] = Cell.CONTROL_CENTER
	_redraw()
	emit_signal("map_config_updated")

func _redraw() -> void:
	clear()
	for y in range(h + 4):
		for x in range(w + 4):
			_paint_cell(Vector2i(x - int((w + 4) * 0.5), y - int((h + 4) * 0.5)), cells[y][x])

func _paint_cell(c: Vector2i, state: int) -> void:
	var atlas_coords: Vector2i
	match state:
		Cell.UNKNOWN:
			atlas_coords = Vector2i(0, 0)
		Cell.EXPLORED:
			atlas_coords = Vector2i(1, 0)
		Cell.GOLD:
			atlas_coords = Vector2i(2, 0)
		Cell.SILVER:
			atlas_coords = Vector2i(1, 1)
		Cell.COPPER:
			atlas_coords = Vector2i(0, 1)
		Cell.OBSTACLE:
			atlas_coords = Vector2i(3, 0)
		Cell.CONTROL_CENTER:
			atlas_coords = Vector2i(4, 0)
		Cell.CONTROL_CENTER_GOLD:
			atlas_coords = Vector2i(4, 0)
		Cell.CONTROL_CENTER_SILVER:
			atlas_coords = Vector2i(4, 0)
		Cell.CONTROL_CENTER_COPPER:
			atlas_coords = Vector2i(4, 0)
		_:
			atlas_coords = Vector2i(0, 0)

	set_cell(0, c, 0, atlas_coords)

func get_state_centered(c: Vector2i) -> int:
	var offset := int((w + 4) * 0.5)
	var idx_y := offset + c.y
	var idx_x := offset + c.x
	if idx_y < 0 or idx_y >= h + 4 or idx_x < 0 or idx_x >= w + 4:
		return Cell.UNKNOWN
	return cells[idx_y][idx_x]

func set_state_centered(c: Vector2i, state: int) -> void:
	var offset := int((w + 4) * 0.5)
	var idx_y := offset + c.y
	var idx_x := offset + c.x
	if idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4:
		cells[idx_y][idx_x] = state
		_paint_cell(Vector2i(idx_x - offset, idx_y - offset), state)

func in_bounds_centered(c: Vector2i) -> bool:
	var offset := int((w + 4) * 0.5)
	var idx_y := offset + c.y
	var idx_x := offset + c.x
	return idx_y >= 0 and idx_y < h + 4 and idx_x >= 0 and idx_x < w + 4

func is_ore(state: int) -> bool:
	return state == Cell.GOLD or state == Cell.SILVER or state == Cell.COPPER

func ore_to_string(state: int) -> String:
	match state:
		Cell.GOLD:
			return "gold"
		Cell.SILVER:
			return "silver"
		Cell.COPPER:
			return "copper"
		_:
			return ""

func string_to_ore(ore_name: String) -> int:
	match ore_name:
		"gold":
			return Cell.GOLD
		"silver":
			return Cell.SILVER
		"copper":
			return Cell.COPPER
		_:
			return Cell.UNKNOWN


# --- Helpers for centered grid coordinates ---

func grid_size() -> Vector2i:
	return Vector2i(w + 2, h + 2)

func grid_half() -> Vector2i:
	return Vector2i(int((w + 2) * 0.5), int((h + 2) * 0.5))

func to_index_coords(c: Vector2i) -> Vector2i:
	return c + grid_half()

func cell_to_local(c: Vector2i) -> Vector2:
	return map_to_local(c)
