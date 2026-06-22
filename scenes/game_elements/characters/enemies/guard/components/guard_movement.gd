# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name GuardMovement
extends Node2D

signal still_time_finished
signal destination_reached
signal path_blocked

var still_time_left_in_seconds: float = 0.0
var _destination_reached: bool = true
var destination: Vector2 = Vector2.ZERO

@onready var guard: Guard = owner


func _process(delta: float) -> void:
	if still_time_left_in_seconds > 0.0:
		still_time_left_in_seconds = move_toward(still_time_left_in_seconds, 0.0, delta)
		if still_time_left_in_seconds <= 0.0:
			still_time_finished.emit()

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
	if collision and collision.get_travel().length() < collision.get_remainder().length() / 20.0:
		path_blocked.emit()


func calculate_velocity() -> Vector2:
	if still_time_left_in_seconds > 0.0 or _destination_reached:
		return Vector2.ZERO
	return guard.global_position.direction_to(destination) * guard.move_speed


func wait_seconds(time: float) -> void:
	still_time_left_in_seconds = time


func set_destination(new_destination: Vector2) -> void:
	_destination_reached = false
	destination = new_destination


func start_moving_now() -> void:
	still_time_left_in_seconds = 0.0


func start_moving_towards(new_destination: Vector2) -> void:
	set_destination(new_destination)
	still_time_left_in_seconds = 0.0


func stop_moving() -> void:
	destination = guard.global_position


func has_reached_destination() -> bool:
	return _destination_reached
