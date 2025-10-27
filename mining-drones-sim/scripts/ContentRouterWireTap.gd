extends Node

@export var logger_path: NodePath

var _logger: WireTapLogger

func _ready() -> void:
	add_to_group("queue_loggers")
	add_to_group("filtered_loggers")
	call_deferred("_resolve_logger")

func add_log(queue_name: String, ore_type: String, coords: Vector2i) -> void:
	_record({
		"event": "main_queue",
		"queue": queue_name,
		"ore_type": ore_type,
		"coords": _coords_to_dict(coords)
	})

func register_forward(queue_name: String, ore_type: String, coords: Vector2i) -> void:
	_record({
		"event": "forwarded",
		"queue": queue_name,
		"ore_type": ore_type,
		"coords": _coords_to_dict(coords)
	})

func register_consumed(queue_name: String, ore_type: String, coords: Vector2i, consumer: String) -> void:
	_record({
		"event": "consumed",
		"queue": queue_name,
		"ore_type": ore_type,
		"coords": _coords_to_dict(coords),
		"consumer": consumer
	})

func _resolve_logger() -> void:
	var resolved := get_node_or_null(logger_path)
	if not resolved:
		push_warning("ContentRouterWireTap no encontro el logger en %s" % logger_path)
		return

	_logger = resolved as WireTapLogger
	if not _logger:
		push_warning("ContentRouterWireTap encontro un nodo invalido como logger en %s" % logger_path)

func _record(payload: Dictionary) -> void:
	if not _logger:
		return
	var entry := payload.duplicate()
	entry["component"] = "ContentRouterWireTap"
	if _logger.has_method("write_entry"):
		_logger.call("write_entry", entry)

func _coords_to_dict(coords: Vector2i) -> Dictionary:
	return {
		"x": coords.x,
		"y": coords.y
	}
