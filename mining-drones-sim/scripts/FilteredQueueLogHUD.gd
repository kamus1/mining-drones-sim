extends Control

@export var max_entries: int = 20

const GOLD_QUEUE := "gold_output_queue"
const SILVER_QUEUE := "silver_output_queue"
const COPPER_QUEUE := "copper_output_queue"

var _buffers: Dictionary = {}
var _labels: Dictionary = {}

func _ready() -> void:
    add_to_group("filtered_loggers")
    _buffers = {
        GOLD_QUEUE: [],
        SILVER_QUEUE: [],
        COPPER_QUEUE: []
    }

    _register_queue(
        GOLD_QUEUE,
        get_node_or_null("LogContainer/GoldSection/ToggleButton") as Button,
        get_node_or_null("LogContainer/GoldSection/LogPanel/Log") as RichTextLabel
    )

    _register_queue(
        SILVER_QUEUE,
        get_node_or_null("LogContainer/SilverSection/ToggleButton") as Button,
        get_node_or_null("LogContainer/SilverSection/LogPanel/Log") as RichTextLabel
    )

    _register_queue(
        COPPER_QUEUE,
        get_node_or_null("LogContainer/CopperSection/ToggleButton") as Button,
        get_node_or_null("LogContainer/CopperSection/LogPanel/Log") as RichTextLabel
    )

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

    button.toggled.connect(func(pressed: bool) -> void:
        if panel:
            panel.visible = pressed
        label.visible = pressed
        if pressed:
            _update_label(queue_name)
    )

func register_forward(queue_name: String, ore_type: String, coords: Vector2i) -> void:
    var buffer: Array = _ensure_buffer(queue_name)
    var entry: Dictionary = {
        "ore_type": ore_type,
        "coords": coords,
        "consumer": ""
    }
    buffer.append(entry)
    _buffers[queue_name] = buffer
    _trim_buffer(queue_name)
    _refresh_if_visible(queue_name)

func register_consumed(queue_name: String, ore_type: String, coords: Vector2i, consumer: String) -> void:
    var buffer: Array = _ensure_buffer(queue_name)
    var updated: bool = false
    for index in range(buffer.size()):
        var entry := buffer[index] as Dictionary
        if entry == null:
            continue
        if _entry_matches(entry, ore_type, coords):
            entry["consumer"] = consumer
            buffer[index] = entry
            updated = true
            break

    if not updated:
        buffer.append({
            "ore_type": ore_type,
            "coords": coords,
            "consumer": consumer
        })

    _buffers[queue_name] = buffer
    _trim_buffer(queue_name)
    _refresh_if_visible(queue_name)

func _update_label(queue_name: String) -> void:
    var label := _labels.get(queue_name, null) as RichTextLabel
    if not label:
        return

    var buffer: Array = _ensure_buffer(queue_name)
    var lines: Array[String] = []
    for entry_variant in buffer:
        var entry := entry_variant as Dictionary
        if entry == null or entry.is_empty():
            continue
        var ore_type: String = String(entry.get("ore_type", ""))
        var coords: Vector2i = entry.get("coords", Vector2i.ZERO) as Vector2i
        var consumer: String = String(entry.get("consumer", ""))
        var display_consumer: String = consumer if consumer != "" else "pendiente"
        var ore_label: String = ore_type.to_upper()
        lines.append("[%s] (%d, %d) -> %s" % [ore_label, coords.x, coords.y, display_consumer])

    label.text = "\n".join(lines)
    var last_line: int = max(label.get_line_count() - 1, 0)
    label.scroll_to_line(last_line)

func _ensure_buffer(queue_name: String) -> Array:
    if not _buffers.has(queue_name):
        _buffers[queue_name] = []
    return _buffers[queue_name] as Array

func _trim_buffer(queue_name: String) -> void:
    if max_entries <= 0:
        return
    var buffer: Array = _ensure_buffer(queue_name)
    while buffer.size() > max_entries:
        buffer.pop_front()
    _buffers[queue_name] = buffer

func _entry_matches(entry: Dictionary, ore_type: String, coords: Vector2i) -> bool:
    var entry_ore: String = String(entry.get("ore_type", ""))
    var entry_coords: Vector2i = entry.get("coords", Vector2i.ZERO) as Vector2i
    return entry_ore == ore_type and entry_coords == coords

func _refresh_if_visible(queue_name: String) -> void:
    var label := _labels.get(queue_name, null) as RichTextLabel
    if label and label.visible:
        _update_label(queue_name)
