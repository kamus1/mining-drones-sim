extends Camera2D

@export var drag_button: int = MOUSE_BUTTON_LEFT
@export var drag_speed: float = 1.0
@export var zoom_multiplier: float = 1.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

var _dragging := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == drag_button:
		_dragging = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_zoom(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_zoom(-1)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		var delta := Vector2(event.relative) * zoom * drag_speed
		global_position -= delta
		get_viewport().set_input_as_handled()

func _apply_zoom(direction: int) -> void:
	if zoom_multiplier <= 0.0:
		return

	var factor: float = pow(zoom_multiplier, direction)
	var new_zoom: Vector2 = zoom * factor
	var lower: float = min(min_zoom, max_zoom)
	var upper: float = max(min_zoom, max_zoom)
	new_zoom.x = clamp(new_zoom.x, lower, upper)
	new_zoom.y = clamp(new_zoom.y, lower, upper)

	if new_zoom != zoom:
		zoom = new_zoom
