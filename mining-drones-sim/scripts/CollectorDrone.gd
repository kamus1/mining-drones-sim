extends Node2D

@export var speed: float = 100.0
@export var radius: float = 10.0
@export var color: Color = Color.RED

var map: TileMap
var current_cell: Vector2i
var target_cell: Vector2i
var state: String = "going_to_ore"  # "going_to_ore", "returning"

func _ready():
	map = get_node("../../TileMap (Mapa)")
	current_cell = map.control_center_pos
	global_position = map.to_global(map.cell_to_local(current_cell))
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func _process(delta: float):
	if target_cell == Vector2i.ZERO:
		return

	var target_pos = map.to_global(map.cell_to_local(target_cell))
	var direction = (target_pos - global_position).normalized()
	global_position += direction * speed * delta

	# Check if close to target
	if global_position.distance_to(target_pos) < 5.0:
		if state == "going_to_ore":
			# Collect ore
			map.set_state_centered(target_cell, map.Cell.EXPLORED)
			print("Ore collected at ", target_cell)
			# Return to control center
			target_cell = map.control_center_pos
			state = "returning"
		elif state == "returning":
			# Arrived at control center
			print("Collector returned to control center")
			queue_free()  # Remove the drone

func set_target(t: Vector2i):
	target_cell = t
