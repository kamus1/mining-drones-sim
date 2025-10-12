# res://scripts/DroneScout.gd
extends Node2D

@export var tick_seconds: float = 0.15
@export var allow_diagonals: bool = false
@export var radius: float = 10.0
@export var color: Color = Color8(0, 120, 255) # azul

@export var start_cell: Vector2i = Vector2i(0, 0)   # celda de inicio (centro)
@export var map_path: NodePath                      # asigna el TileMap (Mapa) desde el editor o por código

var map: TileMap
var current_cell: Vector2i
var dirs4 := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
var dirs8 := [
	Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
	Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)
]

var _rmq_client: RMQClient
var _channel: RMQChannel

func _ready():
	map = get_node(map_path)
	current_cell = start_cell
	# Coloca el scout en el centro geométrico de la celda
	global_position = map.to_global(map.cell_to_local(current_cell))
	queue_redraw() # para dibujar el círculo

	# Timer de “tick” de exploración
	var t := Timer.new()
	t.wait_time = tick_seconds
	t.autostart = true
	t.one_shot = false
	add_child(t)
	t.timeout.connect(_on_tick)

	# Initialize RMQ
	_rmq_client = RMQClient.new()
	var client_open_error := await _rmq_client.open(
		"localhost",
		5672,
		"guest",
		"guest")
	if client_open_error != OK:
		print_debug("Drone RMQ open error: ", client_open_error)
		return

	_channel = await _rmq_client.channel()
	var queue_declare := await _channel.queue_declare("ore_queue")
	if queue_declare[0] != OK:
		print_debug("Drone queue declare error: ", queue_declare)
		return

func _draw():
	# Círculo azul
	draw_circle(Vector2.ZERO, radius, color)

func _process(_delta: float) -> void:
	if _rmq_client:
		_rmq_client.tick()

func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _rmq_client:
			_rmq_client.close()

func _on_tick():
	_explore_step()

func _explore_step():
	# 1) Leer estado actual
	var st: int = map.get_state_centered(current_cell)

	# 2) Reportar oro
	if st == map.Cell.GOLD:
		# Godot no usa console.log, se usa print()
		print("ORE FOUND at cell: ", current_cell)
		# Send message
		if _channel:
			var publishing_error := await _channel.basic_publish("", "ore_queue", "ore found".to_utf8_buffer())
			if publishing_error != OK:
				print_debug("Drone publish error: ", publishing_error)

	# 3) Marcar explorado si es desconocido
	if st == map.Cell.UNKNOWN:
		map.set_state_centered(current_cell, map.Cell.EXPLORED)

	# 4) Elegir siguiente celda
	var candidates: Array[Vector2i] = []
	var dirs = dirs8 if allow_diagonals else dirs4
	for d in dirs:
		var n: Vector2i = current_cell + d
		if not map.in_bounds_centered(n):
			continue
		var ns: int = map.get_state_centered(n)
		if ns != map.Cell.OBSTACLE:
			candidates.append(n)

	if candidates.is_empty():
		return # atascado

	# Prioriza UNKNOWN, luego aleatorio
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return map.get_state_centered(a) < map.get_state_centered(b)
	)
	var next_cell: Vector2i = candidates.pick_random()

	# 5) "Mover" (salto de celda a celda; simple y determinista)
	current_cell = next_cell
	global_position = map.to_global(map.cell_to_local(current_cell))
