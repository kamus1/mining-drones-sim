extends Node

@export var host: String = "localhost"
@export var port: int = 5672
@export var username: String = "guest"
@export var password: String = "guest"

const SOURCE_QUEUE := "ore_queue"
const GOLD_QUEUE := "gold_queue"
const SILVER_QUEUE := "silver_queue"
const COPPER_QUEUE := "copper_queue"

var _rmq_client: RMQClient
var _channel: RMQChannel

func _ready() -> void:
	_rmq_client = RMQClient.new()

	var client_open_error := await _rmq_client.open(host, port, username, password)
	if client_open_error != OK:
		print_debug("QueueDistributionCenter RMQ open error: ", client_open_error)
		return

	_channel = await _rmq_client.channel()

	if not await _ensure_queue(SOURCE_QUEUE):
		return
	for queue_name in [GOLD_QUEUE, SILVER_QUEUE, COPPER_QUEUE]:
		if not await _ensure_queue(queue_name):
			return

	var consume := await _channel.basic_consume(
		SOURCE_QUEUE,
		func(channel: RMQChannel,
			 method: RMQBasicClass.Deliver,
			 _properties: RMQBasicClass.Properties,
			 body: PackedByteArray):
			var ore_type := _extract_ore_type(body.get_string_from_utf8())
			var target_queue := _queue_for_ore(ore_type)

			if target_queue:
				var publish_error := await channel.basic_publish("", target_queue, body)
				if publish_error != OK:
					print_debug("QueueDistributionCenter publish error: ", publish_error, " for ore type: ", ore_type)
			else:
				print_debug("QueueDistributionCenter unknown ore type: ", ore_type)

			channel.basic_ack(method.delivery_tag),
	)

	if consume[0] != OK:
		print_debug("QueueDistributionCenter consume error: ", consume)
		return

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
		print_debug("QueueDistributionCenter queue declare error for ", queue_name, ": ", declare_result)
		return false
	return true

func _extract_ore_type(message: String) -> String:
	if not message.begins_with("ore:"):
		return ""

	var payload := message.substr(4)
	var pieces := payload.split(":")
	if pieces.is_empty():
		return ""

	return String(pieces[0]).strip_edges().to_lower()

func _queue_for_ore(ore_type: String) -> String:
	match ore_type:
		"gold":
			return GOLD_QUEUE
		"silver":
			return SILVER_QUEUE
		"copper":
			return COPPER_QUEUE
		_:
			return ""
