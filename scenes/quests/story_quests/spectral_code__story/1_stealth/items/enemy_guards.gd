extends Node2D

@onready var guard1: Node2D = $Guard1
@onready var guard2: Node2D = $Guard2

func _ready() -> void:
	# Posiciones únicas para cada guardia
	guard1.position = Vector2(951, 1165)  # Ya está en esta posición según tu imagen
	guard2.position = Vector2(557, 495)   # También está definida

	# Si tienen PathFollow2D, puedes ajustar el offset para que no empiecen igual
	if guard1.has_node("PathFollow2D"):
		guard1.get_node("PathFollow2D").offset = 0.0

	if guard2.has_node("PathFollow2D"):
		guard2.get_node("PathFollow2D").offset = 100.0
