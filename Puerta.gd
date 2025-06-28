extends Area2D

@export var escena_nueva : String

func _on_body_entered(body: Node2D) -> void:
#func _on_body_entered(body: Node2D) -> void:
	# AGREGAR AL JUGADOR A GRUPO "player" Y HACER EL GRUPO GLOBAL
	print("tocar")
	#if body.is_in_group("player"):	
	#	print("¡Jugador detectado! Cambiando escena...")
	#get_tree().change_scene_to_file("res://KILLAWAR_escenas/nivel_2.tscn")#(escena_nueva)
