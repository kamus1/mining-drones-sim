# res://scripts/Main.gd
extends Node2D

@export var num_scouts: int = 5
@export var scout_scene: PackedScene
@export var mapa_path: NodePath   # arrástrale tu TileMap (Mapa) desde el editor

var mapa: TileMap

func _ready():
	mapa = get_node(mapa_path)
	_spawn_scouts()

func _spawn_scouts():
	var cont := $Drones
	for i in range(num_scouts):
		var s := scout_scene.instantiate()
		# Usar ruta absoluta para que el dron resuelva el TileMap correctamente
		s.map_path = mapa.get_path()
		s.start_cell = Vector2i(0, 0)  # centro de tu grilla "centrada"
		cont.add_child(s)
