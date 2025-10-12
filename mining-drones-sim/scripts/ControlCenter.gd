extends Node2D

var _rmq_client : RMQClient
var _channel : RMQChannel

func _ready() -> void:
	_rmq_client = RMQClient.new()
	var client_open_error := await _rmq_client.open(
		"localhost",
		5672,
		"guest",
		"guest")
	if client_open_error != OK:
		print_debug("ControlCenter RMQ open error: ", client_open_error)
		return

	_channel = await _rmq_client.channel()
	var queue_declare := await _channel.queue_declare("ore_queue")
	if queue_declare[0] != OK:
		print_debug("ControlCenter queue declare error: ", queue_declare)
		return

	var consume = await _channel.basic_consume("ore_queue",
		func(channel: RMQChannel,
			 method: RMQBasicClass.Deliver,
			 properties: RMQBasicClass.Properties,
			 body: PackedByteArray):
			var msg = body.get_string_from_utf8()
			if msg.begins_with("ore:"):
				var coords_str = msg.substr(4)
				var coords = coords_str.split(",")
				if coords.size() == 2:
					var x = int(coords[0])
					var y = int(coords[1])
					print("ore found at coordinates: (", x, ", ", y, ")")
					# Spawn collector
					get_parent().spawn_collector(Vector2i(x, y))
			channel.basic_ack(method.delivery_tag),
		)
	if consume[0] != OK:
		print_debug("ControlCenter consume error: ", consume)
		return

func _process(_delta: float) -> void:
	if _rmq_client:
		_rmq_client.tick()

func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _rmq_client:
			_rmq_client.close()
