extends Node

var max_health: int = 150
var current_health: int = 150
var primera_carga: bool = true
var cinematica_actual: Node = null 
var anim_player_intro: AnimationPlayer = null

func cambiar_sprite_intro(nombre: String) -> void:
	if cinematica_actual:
		if cinematica_actual.has_method("cambiar_sprite"):
			cinematica_actual.cambiar_sprite(nombre)
		else:
			print("ERROR: Intro.gd no tiene la función 'cambiar_sprite'")
	else:
		print("ERROR: No se ha conectado la cinemática a DatosGlobales")

func mover_personaje_intro(nombre: String) -> void:
	if cinematica_actual:
		if cinematica_actual.has_method("mover_personaje"):
			cinematica_actual.mover_personaje(nombre)
		else:
			print("ERROR: Intro.gd no tiene la función 'mover_personaje'")
