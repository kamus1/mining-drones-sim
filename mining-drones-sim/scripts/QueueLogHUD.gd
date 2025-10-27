extends Control

@export var max_entries: int = 20

const GOLD_QUEUE := "gold_queue"
const SILVER_QUEUE := "silver_queue"
const COPPER_QUEUE := "copper_queue"

var _buffers: Dictionary = {}
var _labels: Dictionary = {}

func _ready() -> void:
	add_to_group("queue_loggers")
	_buffers = {
		GOLD_QUEUE: [],
		SILVER_QUEUE: [],
		COPPER_QUEUE: []
	}

	_register_queue(GOLD_QUEUE,
		get_node_or_null("LogContainer/GoldSection/ToggleButton") as Button,
		get_node_or_null("LogContainer/GoldSection/LogPanel/Log") as RichTextLabel)

	_register_queue(SILVER_QUEUE,
		get_node_or_null("LogContainer/SilverSection/ToggleButton") as Button,
		get_node_or_null("LogContainer/SilverSection/LogPanel/Log") as RichTextLabel)

	_register_queue(COPPER_QUEUE,
		get_node_or_null("LogContainer/CopperSection/ToggleButton") as Button,
		get_node_or_null("LogContainer/CopperSection/LogPanel/Log") as RichTextLabel)

func _register_queue(queue_name: String, button: Button, label: RichTextLabel) -> void:
	if not button or not label:
		return

	var panel := label.get_parent() as Control

	button.toggle_mode = true
	button.button_pressed = false
	if panel:
		panel.visible = false
	label.visible = false
	label.scroll_active = true
	label.scroll_following = true
	_labels[queue_name] = label

	button.toggled.connect(func(pressed: bool):
		if panel:
			panel.visible = pressed
		label.visible = pressed
		if pressed:
			_update_label(queue_name)
	)

func add_log(queue_name: String, ore_type: String, coords: Vector2i) -> void:
	if not _buffers.has(queue_name):
		_buffers[queue_name] = []

	var entry := "[%s] (%d, %d)" % [ore_type.to_upper(), coords.x, coords.y]
	var buffer: Array = _buffers[queue_name] as Array
	buffer.append(entry)
	while buffer.size() > max_entries:
		buffer.pop_front()
	_buffers[queue_name] = buffer

	if _labels.has(queue_name) and (_labels[queue_name] as RichTextLabel).visible:
		_update_label(queue_name)

func _update_label(queue_name: String) -> void:
	var label := _labels.get(queue_name, null) as RichTextLabel
	if not label:
		return
	var buffer: Array = _buffers.get(queue_name, []) as Array
	label.text = "\n".join(buffer)
	var last_line: int = max(label.get_line_count() - 1, 0)
	label.scroll_to_line(last_line)
