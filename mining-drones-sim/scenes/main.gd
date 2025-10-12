# res://scripts/Main.gd
extends Node2D

@export var num_scouts: int = 5
@export var scout_scene: PackedScene
@export var mapa_path: NodePath   # arrástrale tu TileMap (Mapa) desde el editor

var mapa: TileMap

func _ready():
	#limitar fps a 60
	Engine.max_fps = 60

	mapa = get_node(mapa_path)
	_create_control_center()
	_spawn_scouts()

func _create_control_center():
	var cc := Node2D.new()
	cc.name = "ControlCenter"
	cc.position = mapa.control_center_pos * 32
	var script = load("res://scripts/ControlCenter.gd")
	cc.set_script(script)
	add_child(cc)

func spawn_collector(target: Vector2i):
	var collector := Node2D.new()
	collector.name = "CollectorDrone"
	var script = load("res://scripts/CollectorDrone.gd")
	collector.set_script(script)
	collector.set_target(target)
	$Drones.add_child(collector)

func _spawn_scouts():
	var cont := $Drones
	for i in range(num_scouts):
		var s := scout_scene.instantiate()
		# Usar ruta absoluta para que el dron resuelva el TileMap correctamente
		s.map_path = mapa.get_path()
		s.start_cell = mapa.control_center_pos  # centro de control
		cont.add_child(s)

func _process(delta: float) -> void:
	$CurrentFPS.text = "FPS: " + str(Engine.get_frames_per_second())
