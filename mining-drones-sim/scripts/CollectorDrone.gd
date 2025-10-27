# res://scripts/CollectorDrone.gd
extends Node2D

@export var speed: float = 100.0
@export var radius: float = 10.0
@export var color: Color = Color.RED
@export var map_path: NodePath

@export_group("Default Visual")
@export var default_sprite_frames: SpriteFrames
@export var default_animation: StringName = &"default"
@export var default_texture: Texture2D
@export var default_sprite_scale: Vector2 = Vector2.ONE
@export var default_modulate: Color = Color.WHITE

@export_group("Gold Visual")
@export var gold_sprite_frames: SpriteFrames
@export var gold_animation: StringName = &"default"
@export var gold_texture: Texture2D
@export var gold_sprite_scale: Vector2 = Vector2.ONE
@export var gold_modulate: Color = Color(1.0, 0.85, 0.0, 1.0)

@export_group("Silver Visual")
@export var silver_sprite_frames: SpriteFrames
@export var silver_animation: StringName = &"default"
@export var silver_texture: Texture2D
@export var silver_sprite_scale: Vector2 = Vector2.ONE
@export var silver_modulate: Color = Color(0.82, 0.82, 0.88, 1.0)

@export_group("Copper Visual")
@export var copper_sprite_frames: SpriteFrames
@export var copper_animation: StringName = &"default"
@export var copper_texture: Texture2D
@export var copper_sprite_scale: Vector2 = Vector2.ONE
@export var copper_modulate: Color = Color(0.8, 0.4, 0.2, 1.0)

@export_group("Rendering")
@export var use_nearest_filter: bool = true
@export_group("")

var map: TileMap
var current_cell: Vector2i
var target_cell: Vector2i
var state: String = "going_to_ore"  # "going_to_ore", "returning"
var ore_type: String = ""
var home_cell: Vector2i = Vector2i.ZERO

var _home_assigned: bool = false
var _has_target: bool = false
var _sprite: Sprite2D
var _anim_sprite: AnimatedSprite2D
var _visual_dirty: bool = true
var _was_near_target: bool = false

func _ready():
	_resolve_map()
	if map and not _home_assigned and home_cell == Vector2i.ZERO:
		home_cell = map.control_center_pos

	current_cell = home_cell
	if map:
		global_position = map.to_global(map.cell_to_local(current_cell))

	_refresh_visual()
	queue_redraw()

func _process(delta: float):
	if _visual_dirty and is_inside_tree():
		_refresh_visual()

	if not _has_target or not map:
		return

	var target_pos: Vector2 = map.to_global(map.cell_to_local(target_cell))
	var direction: Vector2 = (target_pos - global_position)
	var distance: float = direction.length()

	if distance > 1e-3:
		direction = direction / distance
	global_position += direction * speed * delta

	if global_position.distance_to(target_pos) < 5.0:
		if not _was_near_target:
			_on_reached_target()
		_was_near_target = true
	else:
		_was_near_target = false

func _draw():
	if not _sprite and not _anim_sprite:
		draw_circle(Vector2.ZERO, radius, color)

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE and _visual_dirty:
		_refresh_visual()

func set_target(t: Vector2i, ore_name: String = ""):
	target_cell = t
	ore_type = ore_name.to_lower()
	_has_target = true
	_visual_dirty = true

func set_home(home: Vector2i) -> void:
	home_cell = home
	_home_assigned = true

func set_color(new_color: Color) -> void:
	color = new_color
	_visual_dirty = true
	queue_redraw()

func set_map_path(path: NodePath) -> void:
	map_path = path
	if is_inside_tree():
		_resolve_map()
	else:
		call_deferred("_resolve_map")
	_visual_dirty = true

func _on_reached_target():
	current_cell = target_cell

	if state == "going_to_ore":
		if map and map.is_ore(map.get_state_centered(target_cell)):
			map.set_state_centered(target_cell, map.Cell.EXPLORED)
		print("Collector obtained ", ore_type, " at ", target_cell)
		target_cell = home_cell
		_has_target = true
		state = "returning"
	elif state == "returning":
		print("Collector returned to control center")
		queue_free()

func _refresh_visual() -> void:
	if not is_inside_tree():
		return
	_apply_visual_for_ore(ore_type)
	_visual_dirty = false

func _apply_visual_for_ore(ore: String) -> void:
	var config: Dictionary = _get_visual_for_ore(ore)
	var target_scale: Vector2 = config.get("scale", Vector2.ONE)
	var target_modulate: Color = _combine_colors(config.get("modulate", Color.WHITE), color)
	var frames: SpriteFrames = config.get("frames")
	var animation: StringName = config.get("animation", &"default")
	var texture: Texture2D = config.get("texture")

	if frames:
		_use_animated_visual(frames, animation, target_scale, target_modulate)
	elif texture:
		_use_static_visual(texture, target_scale, target_modulate)
	else:
		_clear_visuals()

func _use_animated_visual(frames: SpriteFrames, animation: StringName, sprite_scale: Vector2, sprite_modulate: Color) -> void:
	if _sprite:
		_sprite.queue_free()
		_sprite = null

	if not _anim_sprite:
		_anim_sprite = AnimatedSprite2D.new()
		_anim_sprite.name = "Visual"
		_anim_sprite.centered = true
		_anim_sprite.z_index = 1
		add_child(_anim_sprite)

	_anim_sprite.sprite_frames = frames
	var available: PackedStringArray = frames.get_animation_names()
	var anim_to_play: StringName = animation
	if not available.has(String(animation)):
		anim_to_play = StringName(available[0]) if available.size() > 0 else StringName("")
	if anim_to_play != StringName(""):
		_anim_sprite.play(anim_to_play)

	_anim_sprite.scale = sprite_scale
	_anim_sprite.self_modulate = sprite_modulate
	_set_filter(_anim_sprite)

func _use_static_visual(texture: Texture2D, sprite_scale: Vector2, sprite_modulate: Color) -> void:
	if _anim_sprite:
		_anim_sprite.queue_free()
		_anim_sprite = null

	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "Visual"
		_sprite.centered = true
		_sprite.z_index = 1
		add_child(_sprite)

	_sprite.texture = texture
	_sprite.scale = sprite_scale
	_sprite.self_modulate = sprite_modulate
	_set_filter(_sprite)

func _clear_visuals() -> void:
	if _anim_sprite:
		_anim_sprite.queue_free()
		_anim_sprite = null
	if _sprite:
		_sprite.queue_free()
		_sprite = null

func _get_visual_for_ore(ore: String) -> Dictionary:
	match ore:
		"gold":
			return _visual_dict(gold_sprite_frames, gold_animation, gold_texture, gold_sprite_scale, gold_modulate)
		"silver":
			return _visual_dict(silver_sprite_frames, silver_animation, silver_texture, silver_sprite_scale, silver_modulate)
		"copper":
			return _visual_dict(copper_sprite_frames, copper_animation, copper_texture, copper_sprite_scale, copper_modulate)
		_:
			return _visual_dict(default_sprite_frames, default_animation, default_texture, default_sprite_scale, default_modulate)

func _visual_dict(frames: SpriteFrames, animation: StringName, texture: Texture2D, sprite_scale: Vector2, sprite_modulate: Color) -> Dictionary:
	return {
		"frames": frames,
		"animation": animation,
		"texture": texture,
		"scale": sprite_scale,
		"modulate": sprite_modulate
	}

func _combine_colors(a: Color, b: Color) -> Color:
	return Color(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a)

func _set_filter(node: CanvasItem) -> void:
	if use_nearest_filter:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _resolve_map() -> void:
	if map_path == NodePath(""):
		return
	if map_path.is_absolute() and not is_inside_tree():
		return
	if map_path != NodePath(""):
		map = get_node_or_null(map_path)
	if not map:
		map = get_node_or_null("../../TileMap (Mapa)")
	if not map and is_inside_tree():
		var root := get_tree().get_current_scene()
		if root:
			map = root.get_node_or_null(map_path)
