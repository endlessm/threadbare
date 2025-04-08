# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Player
extends CharacterBody2D

## Controls how the player can interact with the world around them.
enum Mode {
	## Player can explore the world, interact with items and NPCs, but is not
	## engaged in combat. Combat actions are not available in this mode.
	COZY,
	## Player is engaged in combat. Player can use combat actions.
	FIGHTING,
}

## Controls how the player can interact with the world around them.
@export var mode: Mode = Mode.COZY:
	set = _set_mode
@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0
@export_range(10, 100000, 10) var stopping_step: float = 1500.0
@export_range(10, 100000, 10) var moving_step: float = 4000.0

var last_nonzero_axis: Vector2

@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_fighting: Node2D = %PlayerFighting


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if not is_node_ready():
		return
	match mode:
		Mode.COZY:
			_toggle_player_behavior(player_interaction, true)
			_toggle_player_behavior(player_fighting, false)
		Mode.FIGHTING:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, true)


func _toggle_player_behavior(behavior_node: Node2D, is_active: bool):
	behavior_node.visible = is_active
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)


func _ready() -> void:
	_set_mode(mode)


func _process(delta: float) -> void:
	if player_interaction.is_interacting:
		velocity = Vector2.ZERO
		return

	var axis: Vector2 = %PlayerController.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")

	if not axis.is_zero_approx():
		last_nonzero_axis = axis

	var speed: float
	if %PlayerController.is_action_pressed(&"running"):
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


func teleport_to(tele_position: Vector2, smooth_camera: bool = false) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position
