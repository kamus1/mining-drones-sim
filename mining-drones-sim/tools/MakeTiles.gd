# tools/MakeTiles.gd
@tool
extends Node

# Genera un PNG 128x32 (4 columnas de 32 px) con 4 colores sólidos.
# 0=UNKNOWN(negro), 1=EXPLORED(gris), 2=GOLD(amarillo), 3=OBSTACLE(gris oscuro)
func _enter_tree():
	var tile_size := Vector2i(32, 32)
	var cols := 4
	var img := Image.create(tile_size.x * cols, tile_size.y, false, Image.FORMAT_RGBA8)
	var colores := [
		Color.hex(0x000000ff), # UNKNOWN
		Color.hex(0x7f7f7fff), # EXPLORED
		Color.hex(0xffe600ff), # GOLD (amarillo)
		Color.hex(0x444444ff)  # OBSTACLE (roca)
	]
	for i in range(cols):
		img.fill_rect(Rect2i(i*tile_size.x, 0, tile_size.x, tile_size.y), colores[i])
	var tex := ImageTexture.create_from_image(img)
	var path := "res://assets/tiles_32.png"
	img.save_png(path)
	print("> Generado: ", path)
