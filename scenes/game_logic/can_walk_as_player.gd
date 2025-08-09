# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

## Control the character with input actions to walk and run.
class_name CanWalkAsPlayer
extends Node

signal running_changed(is_running: bool)

@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0
@export_range(10, 100000, 10) var stopping_step: float = 1500.0
@export_range(10, 100000, 10) var moving_step: float = 4000.0

var input_vector: Vector2
var is_running: bool:
	set = _set_is_running

# TODO: Add configuration warning to the node if the parent is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	print("%s: I can walk as player" % character.name)


func _unhandled_input(_event: InputEvent) -> void:
	var axis := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var speed: float = run_speed if Input.is_action_pressed(&"running") else walk_speed
	input_vector = axis * speed


func _physics_process(delta: float) -> void:
	var step: float = stopping_step if input_vector.is_zero_approx() else moving_step
	character.velocity = character.velocity.move_toward(input_vector, step * delta)
	character.move_and_slide()

	if character.velocity.is_zero_approx():
		character.animated_sprite_2d.play(&"idle")
	else:
		character.animated_sprite_2d.play(&"walk")

	if not is_zero_approx(character.velocity.x):
		character.look_at_side = (
			Enums.LookAtSide.LEFT if character.velocity.x < 0 else Enums.LookAtSide.RIGHT
		)

	# When using an analogue joystick, this can be false even if the player is
	# holding the "run" button, because the joystick may be inclined only slightly.
	is_running = input_vector.length_squared() > (walk_speed * walk_speed) + 1.0


func _set_is_running(new_is_running: bool) -> void:
	if is_running == new_is_running:
		return
	is_running = new_is_running
	character.animated_sprite_2d.speed_scale = 2.0 if is_running else 1.0
	running_changed.emit(is_running)
