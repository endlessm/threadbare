class_name Player
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

	var axis: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")

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


func teleport_to(position: Vector2, smooth_camera: bool = false):
	# This is something that may need to be reworked since it's pretty fragile
	# The camera eventually may not be called Camera2D, or not be a direct child
	# of the player
	# But then again, in that case this behavior may not be necessary.
	# Besides, eventually the camera may have its own behaviour and script,
	# in which case it could be "teleport aware" and ensure no smoothing is applied in that case

	var camera: Camera2D = get_node_or_null("Camera2D")

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = position
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = position
