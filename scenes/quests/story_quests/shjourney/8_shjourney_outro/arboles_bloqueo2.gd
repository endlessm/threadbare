extends TileMapLayer

var tiles_a_borrar: Array[Vector2i] = [
	Vector2i(17, 25), 
	Vector2i(17, 22),
	Vector2i(17, 24),
	Vector2i(17, 23),
]

func abrir_camino() -> void:
	for celda in tiles_a_borrar:
		set_cell(celda, -1)
	queue_redraw()
	print("Árboles borrados:", tiles_a_borrar)

func _on_sequence_puzzle_assistant_abrir_camino() -> void:
	print("Se recibió señal del diálogo")
	abrir_camino()
