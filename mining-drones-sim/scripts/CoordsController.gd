extends Node

@export var capacity: int = 1000

var _coords := {}

func should_accept(coord: Vector2i) -> bool:
	var key := _to_key(coord)
	if _coords.has(key):
		return false

	_coords[key] = true
	_trim_if_needed()
	return true

func reset() -> void:
	_coords.clear()

func _trim_if_needed() -> void:
	if capacity <= 0:
		return
	while _coords.size() > capacity:
		var first_key: String = _coords.keys()[0]
		_coords.erase(first_key)

func _to_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]
