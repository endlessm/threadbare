extends CharacterBody2D
var speed = 50
var direction = Vector2.ZERO

func _physics_process(delta):
	move_and_slide()
