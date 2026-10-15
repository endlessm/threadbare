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

## Emitted when the character stuck state changes.
signal stuck_changed(is_stuck: bool)

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## The target walking/running velocity according to the input actions.
var input_vector: Vector2

## True if the character is running according to the input actions.
var is_running: bool:
	set = _set_is_running

## True if the character still collides after moving.
var is_stuck: bool:
	set = _set_is_stuck


func _set_is_running(new_is_running: bool) -> void:
	if is_running == new_is_running:
		return
	is_running = new_is_running
	running_changed.emit(is_running)


func _set_is_stuck(new_is_stuck: bool) -> void:
	if is_stuck == new_is_stuck:
		return
	is_stuck = new_is_stuck
	stuck_changed.emit(is_stuck)


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	if not speeds:
		speeds = CharacterSpeeds.new()


func _physics_process(delta: float) -> void:
	var axis := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# On touchscreens, pushing the virtual joystick all the way runs. The length
	# of the axis may fall slightly short of 1, so compare with a threshold.
	var is_input_running := (
		Input.is_action_pressed(&"running")
		or (axis.length_squared() > 0.99 and DisplayServer.is_touchscreen_available())
	)
	var speed := speeds.run_speed if is_input_running else speeds.walk_speed
	input_vector = axis * speed

	var step := (
		speeds.stopping_step
		if character.velocity.length_squared() > input_vector.length_squared()
		else speeds.moving_step
	)
	character.velocity = character.velocity.move_toward(input_vector, step * delta)
	character.move_and_slide()

	# Check if the player got stuck (is colliding after the move_and_slide).
	var collision := character.move_and_collide(Vector2.ZERO, true)
	is_stuck = collision != null

	# When using an analogue joystick, this can be false even if the player is
	# holding the "run" button, because the joystick may be inclined only slightly.
	is_running = input_vector.length_squared() > (speeds.walk_speed * speeds.walk_speed) + 1.0
