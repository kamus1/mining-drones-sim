@tool
extends Node

# Generates a PNG containing all basic tiles used by the map.
# Column order: UNKNOWN, EXPLORED, GOLD, SILVER, COPPER, OBSTACLE, CONTROL_CENTER
func _enter_tree():
	var tile_size := Vector2i(32, 32)
	var cols := 7
	var img := Image.create(tile_size.x * cols, tile_size.y, false, Image.FORMAT_RGBA8)
	var colors := [
		Color.hex(0x000000ff), # UNKNOWN
		Color.hex(0x7f7f7fff), # EXPLORED
		Color.hex(0xffe600ff), # GOLD
		Color.hex(0xbcbcbcff), # SILVER
		Color.hex(0xc87333ff), # COPPER
		Color.hex(0x444444ff), # OBSTACLE
		Color.hex(0x00ff00ff)  # CONTROL_CENTER
	]
	for i in range(cols):
		img.fill_rect(Rect2i(i * tile_size.x, 0, tile_size.x, tile_size.y), colors[i])
	var path := "res://assets/tiles_32.png"
	img.save_png(path)
	print("> Generado: ", path)
