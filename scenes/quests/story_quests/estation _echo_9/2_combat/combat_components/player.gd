extends CharacterBody2D

@export var speed: float = 160.0

func _physics_process(delta):
	var dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	move_and_slide()

	if dir != 0:
		$Sprite2D.flip_h = dir < 0
