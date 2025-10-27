class_name WireTapLogger
extends Node

@export var logs_dir: String = "logs"
@export var file_prefix: String = "wire_tap"

var _file: FileAccess
var _file_path: String = ""
var _resolved_dir: String = ""

func _ready() -> void:
	_open_session()

func write_entry(entry: Dictionary) -> void:
	if not _file:
		return

	var enriched := entry.duplicate()
	enriched["timestamp"] = _current_timestamp()
	_file.store_line(JSON.stringify(enriched))
	_file.flush()

func get_file_path() -> String:
	return _file_path

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_close_session()

func _open_session() -> void:
	_resolved_dir = _resolve_logs_dir()
	var make_dir_error := DirAccess.make_dir_recursive_absolute(_resolved_dir)
	if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
		push_error("WireTapLogger no pudo crear el directorio: %s" % _resolved_dir)
		return

	_file_path = _build_session_path()
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	if not _file:
		push_error("WireTapLogger no pudo abrir archivo: %s" % _file_path)
		return

	write_entry({
		"event": "session_start",
		"component": "WireTapLogger"
	})

func _close_session() -> void:
	if _file:
		write_entry({
			"event": "session_end",
			"component": "WireTapLogger"
		})
		_file.flush()
		_file.close()
		_file = null

func _build_session_path() -> String:
	var stamp := _current_timestamp().replace(":", "").replace("-", "")
	var sanitized_dir := _strip_trailing_slash(_resolved_dir)
	return sanitized_dir.path_join("%s_%s.jsonl" % [file_prefix, stamp])

func _current_timestamp() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		dt.year,
		dt.month,
		dt.day,
		dt.hour,
		dt.minute,
		dt.second
	]

func _resolve_logs_dir() -> String:
	var trimmed := logs_dir.strip_edges()
	if trimmed.is_empty():
		trimmed = "logs"

	if _is_absolute_path(trimmed):
		return trimmed

	if trimmed.begins_with("user://"):
		return trimmed

	if trimmed.begins_with("res://"):
		return ProjectSettings.globalize_path(trimmed)

	var project_root := ProjectSettings.globalize_path("res://")
	return _strip_trailing_slash(project_root).path_join(trimmed)

func _is_absolute_path(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("/"):
		return true
	if path.length() > 1 and path[1] == ":":
		return true
	if path.begins_with("\\\\"):
		return true
	return false

func _strip_trailing_slash(path: String) -> String:
	if path.is_empty():
		return path
	while path.length() > 1 and (path.ends_with("/") or path.ends_with("\\")):
		if path.length() <= 3:
			break
		path = path.left(path.length() - 1)
	return path
