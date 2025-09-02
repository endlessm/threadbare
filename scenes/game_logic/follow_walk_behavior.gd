# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FollowWalkBehavior
extends Node2D
## @experimental
##
## Make the character follow a target.

## Emitted when [member target] becomes reached or not.
signal target_reached_changed(is_reached: bool)

## The character walking speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The speed to consider that the character is stuck.
## If less than [member walk_speed], the character may slide on walls instead of emitting
## the [signal got_stuck] signal.
## If closer to zero, the character may not ever emit the [signal got_stuck] signal.
@export_range(0, 1000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 300.0

## The target to follow.
@export var target: Node2D:
	set = _set_target

## How smooth or sharp is the change of direction.
## Close to zero: smooth.
## Close to one: sharp (immediate).
@export_range(0.1, 1.0, 0.1, "suffix:m") var direction_weight: float = 0.2

## The distance to travel between retargetting.
## If zero, it will constantly retarget.
@export_range(0, 100, 1, "or_greater", "suffix:m") var travel_distance: float = 50.0

## How close should the character be from the target to emit the [signal target_reached_changed]
## signal.
## Note that this distance should be big enough to consider the collision shapes of both
## the target and this character, if they are set to collide, otherwise the
## [signal target_reached_changed] signal may not be ever emitted.
@export_range(0, 400, 1, "or_greater", "suffix:m") var target_reached_distance: float = 200.0

## The current direction as a unit Vector2.
var direction: Vector2

## The current distance travelled since last direction update.
var distance: float = 0

## True if the character has reached the target.
var is_target_reached: bool:
	set = _set_is_target_reached

## The controlled character.
@onready var character: CharacterBody2D = get_parent()


func _set_target(new_target: Node2D) -> void:
	target = new_target
	update_configuration_warnings()


func _set_is_target_reached(new_is_target_reached: bool) -> void:
	if is_target_reached == new_is_target_reached:
		return
	is_target_reached = new_is_target_reached
	target_reached_changed.emit(is_target_reached)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not target:
		warnings.append("Target property must be set.")
	return warnings


func _update_direction() -> void:
	direction = character.global_position.direction_to(target.global_position)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	_update_direction()


func _physics_process(delta: float) -> void:
	if not direction:
		_update_direction()

	character.velocity = character.velocity.lerp(direction * walk_speed, direction_weight)
	var collided := character.move_and_slide()

	if collided and character.is_on_wall():
		if character.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
			_update_direction()
	else:
		distance += walk_speed * delta
		if distance > travel_distance:
			_update_direction()
			distance = 0.0

	is_target_reached = (
		(character.global_position - target.global_position).length_squared()
		<= target_reached_distance * target_reached_distance
	)
