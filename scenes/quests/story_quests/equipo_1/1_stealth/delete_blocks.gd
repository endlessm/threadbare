extends Node2D
@onready var stones = $Stone;

var bloques_a_borrar=[
	Vector2i(44,27),
	Vector2i(44,28),
	Vector2i(44,29),
	Vector2i(44,30),
]
func delete_stones()->void:
	for b in bloques_a_borrar:
		stones.set_cell(b,-1);
