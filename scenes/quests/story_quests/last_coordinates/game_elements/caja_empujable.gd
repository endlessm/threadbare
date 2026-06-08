extends CharacterBody2D

@export var velocidad_empuje: float = 80.0

func empujar(direccion: Vector2) -> void:
	# Multiplicamos la dirección de la colisión por la velocidad
	velocity = direccion * velocidad_empuje
	
	# move_and_slide() maneja automáticamente la detención si hay una pared en la "Mask"
	move_and_slide()
