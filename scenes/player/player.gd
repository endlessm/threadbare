extends CharacterBody2D

@export_range(10, 100000, 10) var WALK_SPEED: float = 300.0
@export_range(10, 100000, 10) var RUN_SPEED: float = 500.0
@export_range(10, 100000, 10) var STOPPING_STEP: float = 1500.0
@export_range(10, 100000, 10) var MOVING_STEP: float = 4000.0

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
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED

	var step: float
	if axis.is_zero_approx():
		step = STOPPING_STEP
	else:
		step = MOVING_STEP

	velocity = velocity.move_toward(axis * speed, step * delta)

	move_and_slide()
