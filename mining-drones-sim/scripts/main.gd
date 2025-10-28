# res://scripts/Main.gd
extends Node2D

@export var num_scouts: int = 5
@export var scout_scene: PackedScene
@export var collector_scene: PackedScene
@export var mapa_path: NodePath 

var mapa: TileMap

func _ready():
	#limitar fps a 60
	Engine.max_fps = 60

	mapa = get_node(mapa_path)
	_spawn_scouts()

# función para spawnear drones recolectores en el mapa
func spawn_collector(target: Vector2i, ore_type: String, home_cell: Vector2i, collector_color: Color):
	var collector: Node2D
	if collector_scene:
		collector = collector_scene.instantiate()
	else:
		collector = Node2D.new()
		collector.name = "CollectorDrone"
		var script := load("res://scripts/CollectorDrone.gd")
		collector.set_script(script)

	if collector.has_method("set_map_path"):
		collector.call("set_map_path", mapa.get_path())

	if collector.name.is_empty():
		collector.name = "CollectorDrone"

	collector.call("set_home", home_cell)
	collector.call("set_color", collector_color)
	collector.call("set_target", target, ore_type)
	$Drones.add_child(collector)

func _spawn_scouts():
	var cont := $Drones
	for i in range(num_scouts):
		var s := scout_scene.instantiate()
		# Usar ruta absoluta para que el dron resuelva el TileMap correctamente
		s.map_path = mapa.get_path()
		s.start_cell = mapa.control_center_pos  # centro de control
		cont.add_child(s)

func _process(_delta: float) -> void:
	$CanvasLayer/HUD/CurrentFPS.text = "FPS: " + str(Engine.get_frames_per_second())
