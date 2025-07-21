extends CharacterBody2D

@export var speed: float = 100.0
@export var top_limit: float = 176.0
@export var bottom_limit: float = 858.0

var direction: int = 1  # 1 = baja, -1 = sube

func _physics_process(_delta: float) -> void:
	velocity.x = speed * direction
	move_and_slide()

	# Cambia de dirección si llegó al límite
	if position.x >= bottom_limit:
		direction = -1
	elif position.x <= top_limit:
		direction = 1
