extends CharacterBody2D

@export var speed: float = 100.0
@export var limite_izquierda: float = 0
@export var limite_derecha: float = 0

var direction: int = 1  # 1 = baja, -1 = sube

func _physics_process(_delta):
	velocity.x = speed * direction
	move_and_slide()

	# Cambia de dirección si llegó al límite
	if position.x >= limite_izquierda:
		direction = -1
	elif position.x <= limite_derecha:
		direction = 1
