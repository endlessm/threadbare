# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MovimientoCustom
extends Node2D

## Emitted when [member still_time_left] reaches 0
signal still_time_finished
## Emitted when [member guard] reached [member destination]
signal destination_reached
## Emitted when [member guard] got stuck trying to reach [member destination]
signal path_blocked

## While this time is greater than 0, the guard won't move
var still_time_left_in_seconds: float = 0.0
var _destination_reached: bool = true

## Target position into which the guard will move, in absolute coordinates
@onready var destination: Vector2 = Vector2.ZERO
# --- AQUÍ ESTÁ EL CAMBIO MÁGICO ---
@onready var guard: GuardiaCustom = owner
# ----------------------------------

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
