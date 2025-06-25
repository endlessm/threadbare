extends Node2D

@export var vida_max = 20
var vida = 20

func recibir_daño(cantidad):
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	print("Jugador recibió ", cantidad, " de daño. Vida: ", vida)
	$vida_del_prota.value = vida
	$vida_del_prota.max_value = vida_max

	if vida <= 0:
		print("muerto :c")
		get_parent().queue_free() 
