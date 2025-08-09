# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FollowWalkBehavior
extends Node2D
## Make the character follow a target.

## Emitted when [member target] is reached.
signal target_reached

## The character walking speed.
@export_range(10, 100000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The target to follow.
@export var target: Node2D

## The distance to travel between retargetting. If zero, it will constantly retarget.
@export_range(0, 100000, 1, "or_greater", "suffix:m") var travel_distance: float = 500.0

## How close should the character be from the target to emit the [signal target_reached] signal.
@export_range(0.1, 1000, 5, "or_greater", "suffix:m") var target_reached_distance: float = 100.0

## The speed to consider that the character is stuck.
## If less than [member walk_speed], the character may slide on walls instead of emitting
## the [signal got_stuck] signal.
## If closer to zero, the character may not ever emit the [signal got_stuck] signal.
@export_range(0, 100000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 300.0

## The current direction as a unit Vector2.
var direction: Vector2

## The current distance travelled since last direction update.
var distance: float = 0

## The controlled character.
@onready var character: CharacterBody2D = get_parent()


func _update_direction() -> void:
	direction = character.global_position.direction_to(target.global_position)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_update_direction()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not direction:
		_update_direction()

	character.velocity = direction * walk_speed
	var collided := character.move_and_slide()

	if collided and character.is_on_wall():
		if character.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
			_update_direction()
	else:
		distance += walk_speed * _delta
		if distance > travel_distance:
			_update_direction()
			distance = 0.0
