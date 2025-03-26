@tool
class_name GuardMovement
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

	# If the distance it was able to travel is a lot lower than the remainder,
	# it's stuck and we can emit the path_blocked signal so the guard can
	# handle that case
	if collision and collision.get_travel().length() < collision.get_remainder().length() / 20.0:
		path_blocked.emit()


## Returns the velocity the guard should have, receives the delta time since
## the last frame as a parameter
func calculate_velocity() -> Vector2:
	if still_time_left_in_seconds > 0.0 or _destination_reached:
		return Vector2.ZERO
	return guard.global_position.direction_to(destination) * guard.move_speed


## Make the guard stop for the given time, in seconds
func wait_seconds(time: float) -> void:
	still_time_left_in_seconds = time


## Sets the next point into which the guard will move.
## It won't make the guard move if [member still_time_left_in_seconds] if
## greater than 0.
func set_destination(new_destination: Vector2) -> void:
	_destination_reached = false
	destination = new_destination


func start_moving_now() -> void:
	still_time_left_in_seconds = 0.0


## Sets the next point into which the guard will move AND makes it start moving
## even if [member still_time_left_in_seconds] was positive.
func start_moving_towards(new_destination: Vector2) -> void:
	set_destination(new_destination)
	still_time_left_in_seconds = 0.0


## Sets the destination to the same point the guard is at so it doesn't try to
## travel to any new point
func stop_moving() -> void:
	destination = guard.global_position
