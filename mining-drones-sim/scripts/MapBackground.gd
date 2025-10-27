extends Node2D

@export var map_path: NodePath
@export var color: Color = Color.WHITE
@export var padding: Vector2 = Vector2.ZERO
@export var background_z_index: int = -100

var _map: TileMap

func _ready() -> void:
	_resolve_map()
	if not _map:
		set_process(true)
	z_index = background_z_index
	queue_redraw()

func _process(_delta: float) -> void:
	if _map:
		set_process(false)
		return
	_resolve_map()
	if _map:
		set_process(false)
		queue_redraw()

func _resolve_map() -> void:
	if map_path == NodePath(""):
		return
	if _map:
		return
	_map = get_node_or_null(map_path)
	if _map:
		if not _map.is_connected("map_config_updated", Callable(self, "_on_map_config_updated")):
			_map.connect("map_config_updated", Callable(self, "_on_map_config_updated"))
		_update_color_from_map()

func _on_map_config_updated() -> void:
	_update_color_from_map()
	queue_redraw()

func _draw() -> void:
	if not _map:
		return

	var tile_size := Vector2(_map.tile_set.tile_size) if _map.tile_set else Vector2(32, 32)
	var used_rect := _map.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	var top_left_cell := used_rect.position
	var bottom_right_cell := used_rect.position + used_rect.size - Vector2i.ONE

	var top_left_world := _map.to_global(_map.map_to_local(top_left_cell)) - tile_size * 0.5
	var bottom_right_world := _map.to_global(_map.map_to_local(bottom_right_cell)) + tile_size * 0.5

	var min_local := to_local(top_left_world)
	var max_local := to_local(bottom_right_world)

	var rect := Rect2(min_local, max_local - min_local)
	rect = rect.grow_individual(padding.x, padding.y, padding.x, padding.y)

	draw_rect(rect, color, true)

func _update_color_from_map() -> void:
	if not _map or not _map.tile_set:
		return
	var source := _map.tile_set.get_source(0)
	if not (source is TileSetAtlasSource):
		return
	var atlas_source := source as TileSetAtlasSource
	var coord := Vector2i.ZERO
	if not atlas_source.has_tile(coord):
		return
	var region := atlas_source.get_tile_texture_region(coord)
	var texture := atlas_source.texture
	if texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return
	var sample_pos := region.position
	sample_pos.x = clamp(sample_pos.x, 0, image.get_width() - 1)
	sample_pos.y = clamp(sample_pos.y, 0, image.get_height() - 1)
	color = image.get_pixelv(sample_pos)
