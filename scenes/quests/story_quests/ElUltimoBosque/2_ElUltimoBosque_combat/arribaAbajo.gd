extends CharacterBody2D

@export var speed: float = 100.0
@export var limite_superior: float = 0
@export var limite_inferior: float = 0

var direction: int = 1  # 1 = baja, -1 = sube

func _physics_process(_delta: float) -> void:
	velocity.y = speed * direction
	move_and_slide()

	# Cambia de dirección si llegó al límite
	if position.y >= limite_inferior:
		direction = -1
	elif position.y <= limite_superior:
		direction = 1
