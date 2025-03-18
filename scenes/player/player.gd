extends CharacterBody2D

@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0
@export_range(10, 100000, 10) var stopping_step: float = 1500.0
@export_range(10, 100000, 10) var moving_step: float = 4000.0

@onready var player_interaction: PlayerInteraction = %PlayerInteraction


func _process(delta: float) -> void:
	if player_interaction.is_interacting:
		velocity = Vector2.ZERO
		return

	var axis: Vector2 = Vector2(
		Input.get_axis(&"ui_left", &"ui_right"),
		Input.get_axis(&"ui_up", &"ui_down"),
	)

	var speed: float
	if Input.is_action_pressed(&"running"):
		speed = run_speed
	else:
		speed = walk_speed

	var step: float
	if axis.is_zero_approx():
		step = stopping_step
	else:
		step = moving_step

	velocity = velocity.move_toward(axis * speed, step * delta)

	move_and_slide()
