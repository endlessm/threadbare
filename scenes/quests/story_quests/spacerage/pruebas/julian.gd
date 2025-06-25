extends Node2D

@export var vida_max = 20
@export var vida = 20

@onready var barra_vida = $vida_barra

func _ready():
	barra_vida.max_value = vida_max
	barra_vida.value = vida

func recibir_daño(cantidad):
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	barra_vida.value = vida
	print("Jugador recibió ", cantidad, " de daño le queda ", vida)

	if vida <= 0:
		print("Jugador murió")
		get_parent().queue_free()  
