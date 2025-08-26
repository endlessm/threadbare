extends TileMapLayer

var tiles_a_borrar: Array[Vector2i] = [
	Vector2i(19, 15), 
	Vector2i(19, 14),
	Vector2i(19, 13),
	Vector2i(19, 12),
	Vector2i(19, 11),
	Vector2i(20, 15), 
	Vector2i(20, 14),
	Vector2i(20, 13),
	Vector2i(20, 12),
	Vector2i(20, 11),
]

func abrir_camino() -> void:
	for celda in tiles_a_borrar:
		set_cell(celda, -1)
	queue_redraw()
	print("Árboles borrados:", tiles_a_borrar)

func _on_sequence_puzzle_assistant_abrir_camino() -> void:
	print("Se recibió señal del diálogo")
	abrir_camino()
