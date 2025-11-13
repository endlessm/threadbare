extends CharacterBody2D

@export var speed: float = 150.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * speed
	
	move_and_slide()
	
	if velocity.length() > 0:
		
		if abs(velocity.x) > abs(velocity.y):
			animated_sprite.play("walk_side")
			
			if velocity.x < 0:
				animated_sprite.flip_h = true
			else:
				animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = false
			
			if velocity.y < 0:
				animated_sprite.play("walk_back")
			else:
				animated_sprite.play("walk_front")
				
	else:
		animated_sprite.play("idle")
