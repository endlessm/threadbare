extends CharacterBody2D

var vida_max=10
var vida = 10

func recibir_daño(cantidad):
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	print("Recibió ", cantidad, " de daño le queda ",vida ," de vida")
	$vida_1.value = vida
	$vida_1.max_value = vida_max
	if vida <= 0:
		queue_free()  #
		print ("murio")
