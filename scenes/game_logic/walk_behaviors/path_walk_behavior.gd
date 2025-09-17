# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name PathWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Make the character walk along a path.
##
## If the path is closed the character walks in circles. If not, they walk back and forth turning
## around in endings.
##
## If the character gets stuck while walking the path, they turn around, unless
## [member turn_around] has been disabled.

## Emitted when [member character] reaches the ending of the path.
signal ending_reached

## Emitted when [member character] got stuck while walking the path.
signal got_stuck

## Emitted when turning around.
signal direction_changed

## Emitted when a "pointy" part of the path is reached.
## This could be used to wait standing for a bit in these points.
## If the path is not closed, both endings are considered pointy so this signal will also
## emit in them.
signal pointy_path_reached

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## The walking path.
@export var walking_path: Path2D:
	set = _set_walking_path

## If set, the character will turn around when reaching the path ending or when stuck.
@export var turn_around: bool = true

## Make the "is path continuous" calculation more or less sensitive.
@export_range(0, 1, 0.01, "or_greater", "suffix:m") var path_continuous_tolerance: float = 0.01

## Make the "is path pointy" calculation more or less sensitive.
@export_range(0, 100, 1, "or_greater", "suffix:m") var path_pointy_tolerance: float = 20

## Position of the first point relative to the path position.
var initial_position: Vector2

## This is 1 when walking in the path direction, and -1 when walking in the opposite direction.
var direction: int = 1:
	set = _set_direction

# Offset of each point that the character will wait standing.
var _standing_offsets: Array[float]


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	update_configuration_warnings()
	if not is_node_ready():
		return
	if walking_path:
		# Set initial position and put character in path:
		initial_position = walking_path.position + walking_path.curve.get_point_position(0)
		character.position = initial_position
		_setup_standing_offsets()


func _set_direction(new_direction: int) -> void:
	direction = signi(new_direction)
	if not is_node_ready():
		return
	direction_changed.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	if not walking_path:
		warnings.append("Walking Path property must be set.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not speeds:
		speeds = CharacterSpeeds.new()

	_set_walking_path(walking_path)


func _physics_process(delta: float) -> void:
	var closest_offset := walking_path.curve.get_closest_offset(
		character.position - initial_position + walking_path.curve.get_point_position(0)
	)
	var new_offset := closest_offset + speeds.walk_speed * delta * direction

	for idx in range(_standing_offsets.size()):
		var point_offset := _standing_offsets[idx]
		if direction == 1:
			if (
				point_offset > closest_offset
				and (point_offset < new_offset or is_equal_approx(point_offset, new_offset))
			):
				pointy_path_reached.emit()
			elif new_offset > walking_path.curve.get_baked_length():
				pointy_path_reached.emit()
		elif direction == -1:
			if (
				point_offset < closest_offset
				and (point_offset > new_offset or is_equal_approx(point_offset, new_offset))
			):
				pointy_path_reached.emit()

	if not _is_path_closed():
		# Turn around in endings:
		if new_offset > walking_path.curve.get_baked_length() or new_offset < 0.0:
			ending_reached.emit()
			if turn_around:
				direction *= -1

	var target_position := (
		initial_position
		+ walking_path.curve.sample_baked(new_offset)
		- walking_path.curve.get_point_position(0)
	)

	character.velocity = character.position.direction_to(target_position) * speeds.walk_speed

	var collided := character.move_and_slide()
	if collided and character.is_on_wall():
		if speeds.is_stuck(character):
			got_stuck.emit()
			if turn_around:
				direction *= -1


func _setup_standing_offsets() -> void:
	for idx in range(walking_path.curve.point_count):
		var point_position := walking_path.curve.get_point_position(idx)
		var p_in := walking_path.curve.get_point_in(idx)
		var p_out := walking_path.curve.get_point_out(idx)
		# Ignore if at this point, the in and out controls make the path continuous and not pointy:
		# TODO: Compare length_squared() < path_pointy_tolerance
		if idx == 0 and not _is_path_closed():
			_standing_offsets.append(walking_path.curve.get_closest_offset(point_position))
		elif idx == walking_path.curve.point_count - 1 and not _is_path_closed():
			# This especial case is because get_closest_offset() returns zero for the last point
			# if the path is closed:
			_standing_offsets.append(walking_path.curve.get_baked_length())
		elif (p_in or p_out) and abs(p_in.cross(p_out)) <= path_continuous_tolerance:
			continue
		else:
			_standing_offsets.append(walking_path.curve.get_closest_offset(point_position))


## Return true if the end of the path is the same point as the beginning.
func _is_path_closed() -> bool:
	if walking_path.curve.point_count < 3:
		return false

	var first_point_position: Vector2 = walking_path.curve.get_point_position(0)
	var last_point_position: Vector2 = walking_path.curve.get_point_position(
		walking_path.curve.point_count - 1
	)

	return first_point_position.is_equal_approx(last_point_position)
