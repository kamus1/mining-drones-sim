# res://scenes/drone_scout.gd
extends Node2D

@export var tick_seconds: float = 0.15
@export var allow_diagonals: bool = false
@export var radius: float = 10.0
@export var color: Color = Color8(0, 120, 255) # fallback debug color
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_frames: SpriteFrames
@export var animation_name: StringName = &"default"
@export var move_duration: float = 0.15

@export var start_cell: Vector2i = Vector2i(0, 0)   # starting cell (centered grid)
@export var map_path: NodePath                      # assign the TileMap (Mapa) from the editor or code

var map: TileMap
var current_cell: Vector2i
var dirs4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
var dirs8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

# Visual variables
var _sprite: Sprite2D
var _anim_sprite: AnimatedSprite2D
var _current_animation: StringName = &""
var _move_tween: Tween
var _moving := false

# RabbitMQ variables
var _rmq_client: RMQClient
var _channel: RMQChannel

func _ready():
	map = get_node(map_path)
	current_cell = start_cell
	# Place the scout in the geometric center of the cell
	global_position = map.to_global(map.cell_to_local(current_cell))
	_setup_visual()
	queue_redraw() # debug circle 

	# Exploration tick timer
	var t := Timer.new()
	t.wait_time = tick_seconds
	t.autostart = true
	t.one_shot = false
	add_child(t)
	t.timeout.connect(_on_tick)

	# Initialize RMQ
	_rmq_client = RMQClient.new()
	var client_open_error := await _rmq_client.open(
		"localhost",
		5672,
		"guest",
		"guest"
	)
	if client_open_error != OK:
		print_debug("Drone RMQ open error: ", client_open_error)
		return

	_channel = await _rmq_client.channel()
	var queue_declare := await _channel.queue_declare("ore_queue")
	if queue_declare[0] != OK:
		print_debug("Drone queue declare error: ", queue_declare)
		return

func _draw():
	if not _sprite and not _anim_sprite:
		# Default visual helper when no sprite is provided
		draw_circle(Vector2.ZERO, radius, color)

func _process(_delta: float) -> void:
	if _rmq_client:
		_rmq_client.tick()
	if _anim_sprite and _current_animation != &"" and not _anim_sprite.is_playing():
		_anim_sprite.play(_current_animation)

func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _rmq_client:
			_rmq_client.close()

func _on_tick():
	if _moving:
		return
	_explore_step()

func _explore_step():
	# 1) Read current state
	var st: int = map.get_state_centered(current_cell)

	# 2) Report ore if found
	if map.is_ore(st):
		var ore_name: String = map.ore_to_string(st)
		print("ORE FOUND (", ore_name, ") at cell: ", current_cell)
		if _channel and ore_name != "":
			var msg := "ore:%s:%d,%d" % [ore_name, current_cell.x, current_cell.y]
			var publishing_error := await _channel.basic_publish("", "ore_queue", msg.to_utf8_buffer())
			if publishing_error != OK:
				print_debug("Drone publish error: ", publishing_error)

	# 3) Mark explored if unknown
	if st == map.Cell.UNKNOWN:
		map.set_state_centered(current_cell, map.Cell.EXPLORED)

	# 4) Choose next cell
	var candidates: Array[Vector2i] = []
	var dirs: Array[Vector2i] = dirs8 if allow_diagonals else dirs4
	for d in dirs:
		var n: Vector2i = current_cell + d
		if not map.in_bounds_centered(n):
			continue
		var ns: int = map.get_state_centered(n)
		if ns != map.Cell.OBSTACLE:
			candidates.append(n)

	if candidates.is_empty():
		return # stuck

	# Prioritize UNKNOWN, then random fallback
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return map.get_state_centered(a) < map.get_state_centered(b)
	)
	var next_cell: Vector2i = candidates.pick_random()

	# 5) Move smoothly toward the target cell
	_start_movement(next_cell)

func _setup_visual() -> void:
	if sprite_frames:
		if _sprite:
			_sprite.queue_free()
			_sprite = null
		if not _anim_sprite:
			_anim_sprite = AnimatedSprite2D.new()
			_anim_sprite.name = "Visual"
			_anim_sprite.centered = true
			_anim_sprite.z_index = 1
			add_child(_anim_sprite)
		_anim_sprite.sprite_frames = sprite_frames
		var available := sprite_frames.get_animation_names()
		var chosen_animation: StringName = StringName("")
		if animation_name != StringName("") and available.has(String(animation_name)):
			chosen_animation = animation_name
		elif available.size() > 0:
			chosen_animation = StringName(available[0])
		_current_animation = chosen_animation
		if _current_animation != &"":
			_anim_sprite.play(_current_animation)
	elif sprite_texture:
		_current_animation = &""
		if _anim_sprite:
			_anim_sprite.queue_free()
			_anim_sprite = null
		if not _sprite:
			_sprite = Sprite2D.new()
			_sprite.name = "Visual"
			_sprite.centered = true
			_sprite.z_index = 1
			add_child(_sprite)
		_sprite.texture = sprite_texture
		_sprite.scale = sprite_scale
	else:
		_current_animation = &""
		if _anim_sprite:
			_anim_sprite.queue_free()
			_anim_sprite = null
		if _sprite:
			_sprite.queue_free()
			_sprite = null
	queue_redraw()

func _start_movement(target_cell: Vector2i) -> void:
	var target_pos := map.to_global(map.cell_to_local(target_cell))
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	if move_duration <= 0.0:
		global_position = target_pos
		current_cell = target_cell
		_moving = false
		return
	var final_cell := target_cell
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", target_pos, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_moving = true
	_move_tween.finished.connect(func():
		current_cell = final_cell
		_moving = false
	)
