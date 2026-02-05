# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name GuardMovement
extends Node2D

## Emitted when [member guard] reached [member destination]
signal destination_reached
## Emitted when [member guard] got stuck trying to reach [member destination]
signal path_blocked

var _destination_reached: bool = true

## Target position into which the guard will move, in absolute coordinates
@onready var destination: Vector2 = Vector2.ZERO
@onready var guard: Guard = owner


func _process(delta: float) -> void:
	if (
		not _destination_reached
		and guard.global_position.distance_to(destination) <= guard.velocity.length() * delta
	):
		_destination_reached = true
		destination_reached.emit()


func move() -> void:
	guard.velocity = calculate_velocity()

	guard.move_and_slide()
	var collision: KinematicCollision2D = guard.get_last_slide_collision()

	# If the distance it was able to travel is a lot lower than the remainder,
	# it's stuck and we can emit the path_blocked signal so the guard can
	# handle that case
	if collision and collision.get_travel().length() < collision.get_remainder().length() / 20.0:
		path_blocked.emit()


## Returns the velocity the guard should have, receives the delta time since
## the last frame as a parameter
func calculate_velocity() -> Vector2:
	if _destination_reached:
		return Vector2.ZERO
	return guard.global_position.direction_to(destination) * guard.move_speed


## Sets the next point into which the guard will move.
func set_destination(new_destination: Vector2) -> void:
	_destination_reached = false
	destination = new_destination


## Sets the destination to the same point the guard is at so it doesn't try to
## travel to any new point
func stop_moving() -> void:
	destination = guard.global_position
