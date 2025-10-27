extends PanelContainer

@export var min_size: Vector2 = Vector2(220, 80)
@export var resize_margin: float = 16.0

var _resizing := false
var _drag_start_pos := Vector2.ZERO
var _start_size := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = min_size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _in_resize_corner(event.position):
			_resizing = true
			_drag_start_pos = event.position
			_start_size = size
			accept_event()
		elif _resizing and not event.pressed:
			_resizing = false
			accept_event()
	elif event is InputEventMouseMotion:
		if _resizing:
			var delta: Vector2 = event.position - _drag_start_pos
			var new_size: Vector2 = _start_size + delta
			new_size.x = max(new_size.x, min_size.x)
			new_size.y = max(new_size.y, min_size.y)
			custom_minimum_size = new_size
			size = new_size
			accept_event()
		else:
			if _in_resize_corner(event.position):
				mouse_default_cursor_shape = Control.CURSOR_DRAG
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW

func _in_resize_corner(local_pos: Vector2) -> bool:
	return local_pos.x >= size.x - resize_margin and local_pos.y >= size.y - resize_margin
