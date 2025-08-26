extends TileMapLayer

var tiles_a_borrar: Array[Vector2i] = [
	Vector2i(12, 29), Vector2i(13, 29),
	Vector2i(12, 28), Vector2i(13, 28),
	Vector2i(12, 27), Vector2i(13, 27),
]

func abrir_camino() -> void:
	for celda in tiles_a_borrar:
		set_cell(celda, -1)
	queue_redraw()
	print("Árboles borrados:", tiles_a_borrar)

func _on_sequence_puzzle_assistant_abrir_camino() -> void:
	print("Se recibió señal del diálogo")
	abrir_camino()
