# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ErraticWalkBehavior
extends Node2D
## Make the character walk around erratically.
##
## TODO:
## - Emit signals and hook with ThrowingEnemy
## - Try it in another game entity
## - Constrain to an area

## Emitted when [member character] got stuck while walking.
signal got_stuck

## Emitted when [member direction] is updated.
signal direction_changed

## The character walking speed.
@export_range(10, 100000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The speed to consider that the character is stuck.
## If less than [member walk_speed], the character may slide on walls instead of emitting
## the [signal got_stuck] signal.
## If closer to zero, the character may not ever emit the [signal got_stuck] signal.
@export_range(0, 100000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 100.0

## The turn direction will be randomly picked between this and [member turn_angle_end].
@export_range(0, 180, 1, "radians_as_degrees") var turn_angle_left: float = PI / 2.0

## The turn direction will be randomly picked between [member turn_angle_start] and this.
@export_range(0, 180, 1, "radians_as_degrees") var turn_angle_right: float = PI / 2.0

## The distance to travel between turns.
@export_range(10, 100000, 1, "or_greater", "suffix:m") var travel_distance: float = 500.0

## The current walking direction.
var direction: Vector2

## The current distance travelled since last turn.
var distance: float = 0

## The controlled character.
@onready var character: CharacterBody2D = get_parent()


func _update_direction() -> void:
	if not direction:
		direction = Vector2.from_angle(randf_range(0, TAU))
	else:
		direction = direction.rotated(randf_range(-turn_angle_left, turn_angle_right))
	direction_changed.emit()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not direction:
		_update_direction()

	character.velocity = direction * walk_speed
	var collided := character.move_and_slide()
	if collided and character.is_on_wall():
		if character.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
			got_stuck.emit()
			_update_direction()
			distance = 0.0
	else:
		distance += walk_speed * _delta
		if distance > travel_distance:
			_update_direction()
			distance = 0.0
