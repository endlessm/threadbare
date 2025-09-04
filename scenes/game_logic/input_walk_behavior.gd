# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InputWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Control the character with input actions to walk and run.

## Emitted when the character starts or stops running.
signal running_changed(is_running: bool)

## The character walking speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The character running speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var run_speed: float = 500.0

## How fast does the player transition from walking/running to stopped.
## A low value will make the character look as slipping on ice.
## A high value will stop the character immediately.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var stopping_step: float = 1500.0

## How fast does the player transition from stopped to walking/running.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var moving_step: float = 4000.0

## The target walking/running velocity according to the input actions.
var input_vector: Vector2

## True if the character is running according to the input actions.
var is_running: bool:
	set = _set_is_running


func _set_is_running(new_is_running: bool) -> void:
	if is_running == new_is_running:
		return
	is_running = new_is_running
	running_changed.emit(is_running)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return


func _unhandled_input(_event: InputEvent) -> void:
	var axis := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var speed: float = run_speed if Input.is_action_pressed(&"running") else walk_speed
	input_vector = axis * speed


func _physics_process(delta: float) -> void:
	var step: float = stopping_step if input_vector.is_zero_approx() else moving_step
	character.velocity = character.velocity.move_toward(input_vector, step * delta)
	character.move_and_slide()

	# When using an analogue joystick, this can be false even if the player is
	# holding the "run" button, because the joystick may be inclined only slightly.
	is_running = input_vector.length_squared() > (walk_speed * walk_speed) + 1.0
