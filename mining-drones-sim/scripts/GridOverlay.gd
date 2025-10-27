extends Node2D

@export var cell_size: int = 32
@export var map_path: NodePath
@export var line_color: Color = Color.BLACK
@export var line_width: float = 1.5
var _map: TileMap
var _used_rect := Rect2i()

func _ready():
	set_process(true)
	_map = get_node_or_null(map_path)
	if _map:
		global_transform = _map.global_transform
	_sync_with_map()

func _process(_delta: float) -> void:
	if not _map:
		return

	if global_transform != _map.global_transform:
		global_transform = _map.global_transform
		queue_redraw()

	var rect := _map.get_used_rect()
	if rect != _used_rect:
		_used_rect = rect
		_sync_with_map()

func _draw():
	if not _map or _used_rect.size == Vector2i.ZERO:
		return

	var origin_cell := _used_rect.position
	var origin_center := _map.map_to_local(origin_cell)
	var x_step := _map.map_to_local(origin_cell + Vector2i(1, 0)) - origin_center
	var y_step := _map.map_to_local(origin_cell + Vector2i(0, 1)) - origin_center
	var top_left := origin_center - (x_step * 0.5) - (y_step * 0.5)
	var width := _used_rect.size.x
	var height := _used_rect.size.y

	for x in range(width + 1):
		var start := top_left + x_step * float(x)
		var end := start + y_step * float(height)
		draw_line(start, end, line_color, line_width)

	for y in range(height + 1):
		var start := top_left + y_step * float(y)
		var end := start + x_step * float(width)
		draw_line(start, end, line_color, line_width)

func _sync_with_map() -> void:
	if not _map:
		return

	var tileset := _map.tile_set
	if tileset:
		cell_size = tileset.tile_size.x

	_used_rect = _map.get_used_rect()
	queue_redraw()
