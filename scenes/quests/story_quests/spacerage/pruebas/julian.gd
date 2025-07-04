extends Area2D

@export var vida_max = 20
@export var vida = 20

@onready var barra_vida = $vida_barra
@onready var daño_player_sonido = $AudioStreamPlayer2D



func recibir_daño(cantidad):
	daño_player_sonido.play()
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	barra_vida.value = vida
	print("Jugador recibió ", cantidad, " de daño. Le queda ", vida)

	if vida <= 0:
		print("Jugador murió")
		emit_signal("jugador_muerto")
		#get_parent().queue_free()  
		SceneSwitcher.reload_with_transition()
		
