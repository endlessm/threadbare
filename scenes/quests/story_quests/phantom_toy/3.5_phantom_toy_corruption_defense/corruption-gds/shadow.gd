extends CharacterBody2D

@export var move_speed := 500.0
@onready var movement_sound: AudioStreamPlayer2D = $ShadowMovementSound

var moving := false
var target_position: Vector2


func move_to(position: Vector2):

	target_position = position

	moving = true

	$AnimatedSprite2D.play("walk")

	movement_sound.play()
	
func stop_shadow() -> void:

	moving = false

	velocity = Vector2.ZERO

	$AnimatedSprite2D.play("idle")

	movement_sound.stop()
	
func _physics_process(delta):

	if not moving:
		return

	var direction = target_position - global_position

	if direction.length() < 10:

		moving = false

		velocity = Vector2.ZERO

		$AnimatedSprite2D.play("idle")
		
		movement_sound.stop()

		return

	velocity = direction.normalized() * move_speed

	$AnimatedSprite2D.flip_h = direction.x < 0

	move_and_slide()
