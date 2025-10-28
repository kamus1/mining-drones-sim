extends Node2D

const MapScript := preload("res://scripts/Mapa.gd")

# RabbitMQ GDNative module data configuration
@export var host: String = "localhost"
@export var port: int = 5672
@export var username: String = "guest"
@export var password: String = "guest"
@export var queue_name: String = "" # el nombre de la cola se define en el editor del proyecto, depende de que tipo es el centro de control


# Control Center configuration
@export var home_cell: Vector2i = Vector2i.ZERO
@export var map_path: NodePath
@export var collector_color: Color = Color.RED

# variables para la personalización del centro de control
var _control_cell_state: int = MapScript.Cell.CONTROL_CENTER
var _control_cell_color: Color = Color(0.18, 0.62, 1.0, 1.0)
var _use_color_overlay: bool = true
var _tile_draw_size: Vector2 = Vector2(32, 32)
var _control_sprite: Texture2D = null
var _control_sprite_scale: Vector2 = Vector2.ONE

@export var control_cell_state: int = MapScript.Cell.CONTROL_CENTER:
	get:
		return _control_cell_state
	set(value):
		_control_cell_state = value
		_update_control_cell_state()

@export var control_cell_color: Color = Color(0.18, 0.62, 1.0, 1.0):
	get:
		return _control_cell_color
	set(value):
		_control_cell_color = value
		_update_color_overlay()

@export var use_color_overlay: bool = true:
	get:
		return _use_color_overlay
	set(value):
		_use_color_overlay = value
		_update_color_overlay()

@export var control_sprite: Texture2D:
	get:
		return _control_sprite
	set(value):
		_control_sprite = value
		_apply_custom_sprite()

@export var control_sprite_scale: Vector2 = Vector2.ONE:
	get:
		return _control_sprite_scale
	set(value):
		_control_sprite_scale = value
		_apply_custom_sprite()

# variables para la conexión RabbitMQ
var _rmq_client: RMQClient
var _channel: RMQChannel
var _map: TileMap


func _ready() -> void:
	_map = get_node_or_null(map_path)
	if _map:
		if home_cell == Vector2i.ZERO:
			home_cell = _map.control_center_pos
		global_position = _map.to_global(_map.cell_to_local(home_cell))
		var tile_set := _map.tile_set
		if tile_set:
			_tile_draw_size = Vector2(tile_set.tile_size)
		_update_control_cell_state()
	_update_color_overlay()
	_apply_custom_sprite()

	if queue_name.is_empty():
		print_debug("ControlCenter requires a queue_name.")
		return

	_rmq_client = RMQClient.new()
	var client_open_error := await _rmq_client.open(host, port, username, password)
	if client_open_error != OK:
		print_debug("ControlCenter RMQ open error: ", client_open_error)
		return

	_channel = await _rmq_client.channel()

	var queue_declare := await _channel.queue_declare(queue_name)
	if queue_declare[0] != OK:
		print_debug("ControlCenter queue declare error (", queue_name, "): ", queue_declare)
		return

	var consume := await _channel.basic_consume(
		queue_name,
		func(channel: RMQChannel,
			 method: RMQBasicClass.Deliver,
			 _properties: RMQBasicClass.Properties,
			 body: PackedByteArray):
			var parsed := _parse_message(body.get_string_from_utf8())
			if parsed:
				var ore_type: String = parsed["ore_type"]
				var coords: Vector2i = parsed["coords"]
				print("ore found (", ore_type, ") at coordinates: (", coords.x, ", ", coords.y, ") from ", queue_name)
				get_tree().call_group("filtered_loggers", "register_consumed", queue_name, ore_type, coords, name)
				var parent := get_parent()
				if parent and parent.has_method("spawn_collector"):
					parent.spawn_collector(coords, ore_type, home_cell, collector_color)
			channel.basic_ack(method.delivery_tag),
	)

	if consume[0] != OK:
		print_debug("ControlCenter consume error (", queue_name, "): ", consume)

func _process(_delta: float) -> void:
	if _rmq_client:
		_rmq_client.tick()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _rmq_client:
			_rmq_client.close()

func _draw() -> void:
	if not _use_color_overlay:
		return
	var half_size := _tile_draw_size * 0.5
	draw_rect(Rect2(-half_size, _tile_draw_size), _control_cell_color, true)

func _update_control_cell_state() -> void:
	if not _map:
		return
	_map.set_state_centered(home_cell, _control_cell_state)

func _apply_custom_sprite() -> void:
	if not is_inside_tree():
		return
	if not _control_sprite:
		var existing_sprite := get_node_or_null("ControlSprite")
		if existing_sprite:
			existing_sprite.queue_free()
		queue_redraw()
		return
	var sprite := get_node_or_null("ControlSprite")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "ControlSprite"
		add_child(sprite)
	sprite.texture = _control_sprite
	sprite.centered = true
	sprite.position = Vector2.ZERO
	sprite.scale = _control_sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _update_color_overlay() -> void:
	queue_redraw()

func _parse_message(msg: String) -> Dictionary:
	if not msg.begins_with("ore:"):
		return {}

	var payload := msg.substr(4)
	var pieces := payload.split(":")
	if pieces.size() != 2:
		return {}

	var ore_type := String(pieces[0]).strip_edges().to_lower()
	var coords := pieces[1].split(",")
	if coords.size() != 2:
		return {}

	return {
		"ore_type": ore_type,
		"coords": Vector2i(int(coords[0]), int(coords[1]))
	}
