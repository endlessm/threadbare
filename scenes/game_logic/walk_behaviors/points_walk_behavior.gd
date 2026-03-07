# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name PointsWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Make the character walk through the points of a path.
##
## If the path is closed the character walks in circles. If not, they walk back and forth turning
## around in endings.
## [br][br]
## If the character gets stuck while walking the path, they turn around.

## Emitted when [member character] reaches the ending of the path.
signal ending_reached

## Emitted when a point of the path is reached.
## This could be used to wait standing for a bit in these points.
signal point_reached

## Emitted when [member character] got stuck while walking the path.
signal got_stuck

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## The walking path.
@export var walking_path: Path2D:
	set = _set_walking_path

## Index of the previous patrol point, -1 means that there isn't a previous
## point yet.
var previous_point_index: int = -1

## Index of the current patrol point.
var current_point_index: int = 0

## The walking target position.
var target_position: Vector2

## True if the [member walking_path] is closed, in which case the character will walk in
## circles.
var is_path_closed: bool


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	update_configuration_warnings()
	if walking_path:
		_advance_target_patrol_point()
		var local_point_position: Vector2 = walking_path.curve.get_point_position(
			current_point_index
		)
		target_position = walking_path.to_global(local_point_position)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	if not walking_path:
		warnings.append("Walking Path property must be set.")
	return warnings


func _ready() -> void:
	super._ready()

	if not speeds:
		speeds = CharacterSpeeds.new()

	_set_walking_path(walking_path)


func _physics_process(delta: float) -> void:
	character.velocity = character.global_position.direction_to(target_position) * speeds.walk_speed
	character.move_and_slide()

	var collision: KinematicCollision2D = character.get_last_slide_collision()

	# If the distance it was able to travel is a lot lower than the remainder,
	# it's stuck and we can emit the path_blocked signal so the guard can
	# handle that case
	if collision and collision.get_travel().length() < collision.get_remainder().length() / 20.0:
		if previous_point_index > -1:
			var new_patrol_point: int = previous_point_index
			previous_point_index = current_point_index
			current_point_index = new_patrol_point
		got_stuck.emit()

	if (
		(
			character.global_position.distance_to(target_position)
			<= character.velocity.length() * delta
		)
		and walking_path
	):
		if (
			(current_point_index == walking_path.curve.point_count - 1)
			or (current_point_index == 0)
		):
			ending_reached.emit()
		_advance_target_patrol_point()
		var local_point_position: Vector2 = walking_path.curve.get_point_position(
			current_point_index
		)
		target_position = walking_path.to_global(local_point_position)
		point_reached.emit()


## Return true if the end of the path is the same point as the beginning.
func _is_path_closed() -> bool:
	if walking_path.curve.point_count < 3:
		return false

	var first_point_position: Vector2 = walking_path.curve.get_point_position(0)
	var last_point_position: Vector2 = walking_path.curve.get_point_position(
		walking_path.curve.point_count - 1
	)

	return first_point_position.is_equal_approx(last_point_position)


## Calculate and set the next point in the patrol path.
## The guard would circle back if the path is open, and go in rounds if the
## path is closed.
func _advance_target_patrol_point() -> void:
	# TODO: Assume as existing and add an editor warning instead.
	if not walking_path or not walking_path.curve or walking_path.curve.point_count < 2:
		return

	var new_patrol_point_idx: int

	if _is_path_closed():
		# amount of points - 1 is used here because in a closed path, the
		# last and first patrol points are the same. So, this lets us skip
		# that repeated point and go for the first one that is different
		new_patrol_point_idx = (current_point_index + 1) % (walking_path.curve.point_count - 1)
	else:
		var at_last_point: bool = current_point_index == (walking_path.curve.point_count - 1)
		var at_first_point: bool = current_point_index == 0
		var going_backwards_in_path: bool = previous_point_index > current_point_index
		if at_last_point:
			# When reaching the end of the path, it starts walking back
			new_patrol_point_idx = current_point_index - 1
		elif at_first_point:
			# If it's at first point is either because it was walking back
			# or because it's the first time it will move, in any case, it moves
			# forward
			new_patrol_point_idx = current_point_index + 1
		elif going_backwards_in_path:
			new_patrol_point_idx = current_point_index - 1
		else:
			new_patrol_point_idx = current_point_index + 1

	previous_point_index = current_point_index
	current_point_index = new_patrol_point_idx
