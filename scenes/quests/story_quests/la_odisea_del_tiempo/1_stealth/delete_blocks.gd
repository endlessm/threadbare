# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@onready var stones = $Stone;

var bloques_a_borrar=[
	Vector2i(44,28),
	Vector2i(44,29),
	Vector2i(44,30),
]
var bloques_a_colocar=[
	Vector2i(51,28),
	Vector2i(51,29),
	Vector2i(51,30),
]
func delete_stones()->void:
	for b in bloques_a_borrar:
		stones.set_cell(b,-1);
func put_stones()->void:
	for b in bloques_a_colocar:
		stones.set_cell(b,0,Vector2i(1,1),0)
		
