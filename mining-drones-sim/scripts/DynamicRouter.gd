extends Node

@export var host: String = "localhost"
@export var port: int = 5672
@export var username: String = "guest"
@export var password: String = "guest"
@export var input_queue: String = ""
@export var output_queue: String = ""
@export var coords_controller_path: NodePath

var _rmq_client: RMQClient
var _channel: RMQChannel
var _coords_controller: Node

func _ready() -> void:
	_coords_controller = get_node_or_null(coords_controller_path)
	if not _coords_controller:
		push_warning("DynamicRouter requires a coords controller node.")

	if input_queue.is_empty() or output_queue.is_empty():
		push_warning("DynamicRouter queues must be configured.")
		return

	_rmq_client = RMQClient.new()
	var open_error := await _rmq_client.open(host, port, username, password)
	if open_error != OK:
		print_debug("DynamicRouter RMQ open error: ", open_error)
		return

	_channel = await _rmq_client.channel()

	if not await _ensure_queue(input_queue):
		return
	if not await _ensure_queue(output_queue):
		return

	var consume := await _channel.basic_consume(
		input_queue,
		func(channel: RMQChannel,
			 method: RMQBasicClass.Deliver,
			 _properties: RMQBasicClass.Properties,
			 body: PackedByteArray):
			await _handle_message(channel, method, body)
	)

	if consume[0] != OK:
		print_debug("DynamicRouter consume error (", input_queue, "): ", consume)

func _process(_delta: float) -> void:
	if _rmq_client:
		_rmq_client.tick()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _rmq_client:
			_rmq_client.close()

func _ensure_queue(queue_name: String) -> bool:
	var declare_result := await _channel.queue_declare(queue_name)
	if declare_result[0] != OK:
		print_debug("DynamicRouter queue declare error (", queue_name, "): ", declare_result)
		return false
	return true

func _handle_message(channel: RMQChannel, method: RMQBasicClass.Deliver, body: PackedByteArray) -> void:
	var msg := body.get_string_from_utf8()
	var parsed := _parse_message(msg)
	var should_forward := true

	if parsed:
		get_tree().call_group("queue_loggers", "add_log", input_queue, parsed["ore_type"], parsed["coords"])

	if parsed and _coords_controller and _coords_controller.has_method("should_accept"):
		var coords: Vector2i = parsed["coords"]
		should_forward = _coords_controller.call("should_accept", coords)

	if should_forward and parsed:
		var publish_error := await channel.basic_publish("", output_queue, body)
		if publish_error != OK:
			print_debug("DynamicRouter publish error (", output_queue, "): ", publish_error)
		else:
			get_tree().call_group("filtered_loggers", "register_forward", output_queue, parsed["ore_type"], parsed["coords"])
	channel.basic_ack(method.delivery_tag)

func _parse_message(msg: String) -> Dictionary:
	if not msg.begins_with("ore:"):
		return {}

	var payload := msg.substr(4)
	var pieces := payload.split(":")
	if pieces.size() != 2:
		return {}

	var coords_parts := pieces[1].split(",")
	if coords_parts.size() != 2:
		return {}

	return {
		"ore_type": String(pieces[0]).strip_edges().to_lower(),
		"coords": Vector2i(int(coords_parts[0]), int(coords_parts[1]))
	}
