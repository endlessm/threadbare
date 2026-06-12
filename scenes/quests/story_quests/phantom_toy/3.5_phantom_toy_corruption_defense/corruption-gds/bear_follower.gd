extends CharacterBody2D

@export var target: CorruptionPlayer
@export var move_speed := 300.0
@export var delay_index := 20
@export var stop_distance := 70.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta):

	if target == null:
		return

	if target.previous_positions.size() <= delay_index:
		return

	var desired_position = target.previous_positions[delay_index]

	var direction = desired_position - global_position

	if direction.length() > stop_distance:

		velocity = direction.normalized() * move_speed

		sprite.play("walk")
		
		if abs(direction.x) > 5:
			sprite.flip_h = direction.x < 0

	else:

		velocity = Vector2.ZERO

		sprite.play("idle")

	move_and_slide()
