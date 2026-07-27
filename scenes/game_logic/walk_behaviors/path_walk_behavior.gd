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
## [br][br]
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

## True if the [member walking_path] is closed, in which case the character will walk in
## circles.
var is_path_closed: bool

# Offset of each pointy point in the path.
var _pointy_offsets: Array[float]


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	update_configuration_warnings()
	if not is_node_ready():
		return
	if walking_path:
		# Set initial position and put character in path:
		var initial_position_local := walking_path.curve.get_point_position(0)
		initial_position = walking_path.to_global(initial_position_local)
		character.global_position = initial_position
		is_path_closed = _is_path_closed()
		_setup_pointy_offsets()


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
	super._ready()
	if Engine.is_editor_hint():
		return

	if not speeds:
		speeds = CharacterSpeeds.new()

	_set_walking_path(walking_path)


## Return a valid offset within the walking path curve.
## If the path is closed, go in circles when crossing the initial position (offset zero).
## If the path is open, clamp to the path length.
func _get_next_offset(offset: float, delta_pixels: float) -> float:
	if is_path_closed:
		return fposmod(offset + delta_pixels, walking_path.curve.get_baked_length())
	return clampf(offset + delta_pixels, 0, walking_path.curve.get_baked_length())


## Return a potentially invalid offset for testing purposes.
## It will be invalid (less than zero or bigger than the curve length) if
## considering the current direction, going from offset to new offset
## has crossed the initial position (offset zero).
func _get_test_offset(offset: float, new_offset: float) -> float:
	if is_path_closed and new_offset * direction < offset:
		# Has crossed initial_position (offset zero)
		return new_offset * direction + walking_path.curve.get_baked_length()
	return new_offset


func _physics_process(delta: float) -> void:
	var offset := get_closest_offset_to_character()
	var delta_pixels := speeds.walk_speed * delta * direction
	var next_offset := _get_next_offset(offset, delta_pixels)

	# A point in the curve that is relative to the point in which the character is,
	# in the given direction, and at a distance that depends on the character walk
	# speed.
	var target_position_local := walking_path.curve.sample_baked(next_offset)
	var target_position := walking_path.to_global(target_position_local)

	# Use the target position above to actually move the character in its direction:
	character.velocity = character.global_position.direction_to(target_position) * speeds.walk_speed
	var collided := character.move_and_slide()

	if collided and character.is_on_wall():
		# Turn around when colliding:
		if speeds.is_stuck(character):
			got_stuck.emit()
			if turn_around:
				direction *= -1
				return

	if not is_path_closed:
		# Turn around in endings:
		if next_offset == walking_path.curve.get_baked_length() or next_offset == 0.0:
			ending_reached.emit()
			if turn_around:
				direction *= -1
				return

	var new_offset := get_closest_offset_to_character()
	var test_offset := _get_test_offset(offset, new_offset)

	# Check if any pointy point is between the closest offset and the new offset,
	# and emit a signal if so.
	for idx in range(_pointy_offsets.size()):
		var pointy_offset := _pointy_offsets[idx]

		if direction == 1:
			if offset > pointy_offset:
				continue
			if pointy_offset <= test_offset:
				pointy_path_reached.emit()
				break
		elif direction == -1:
			if pointy_offset < test_offset:
				continue
			if offset >= pointy_offset:
				pointy_path_reached.emit()
				break


## Return the distance in pixels along the curve
## from the beginning of the path
## to the point that is closest to the character position.
func get_closest_offset_to_character() -> float:
	return walking_path.curve.get_closest_offset(walking_path.to_local(character.global_position))


func _is_curve_smooth(point_in: Vector2, point_out: Vector2) -> bool:
	# TODO: Compare length_squared() < path_pointy_tolerance
	return (point_in or point_out) and abs(point_in.cross(point_out)) <= path_continuous_tolerance


func _setup_pointy_offsets() -> void:
	var add_endings := (
		not is_path_closed
		or not _is_curve_smooth(
			walking_path.curve.get_point_in(walking_path.curve.point_count - 1),
			walking_path.curve.get_point_out(0)
		)
	)

	for idx in range(walking_path.curve.point_count):
		var point_position := walking_path.curve.get_point_position(idx)
		if idx == 0:
			if not add_endings:
				continue
			_pointy_offsets.append(walking_path.curve.get_closest_offset(point_position))
		elif idx == walking_path.curve.point_count - 1:
			if not add_endings:
				continue
			# This especial case is because get_closest_offset() returns zero for the last point.
			_pointy_offsets.append(walking_path.curve.get_baked_length())
		else:
			var p_in := walking_path.curve.get_point_in(idx)
			var p_out := walking_path.curve.get_point_out(idx)
			if _is_curve_smooth(p_in, p_out):
				# The curve is smooth (not pointy) in this point:
				continue
			else:
				_pointy_offsets.append(walking_path.curve.get_closest_offset(point_position))


## Return true if the end of the path is the same point as the beginning.
func _is_path_closed() -> bool:
	if walking_path.curve.point_count < 3:
		return false

	var first_point_position: Vector2 = walking_path.curve.get_point_position(0)
	var last_point_position: Vector2 = walking_path.curve.get_point_position(
		walking_path.curve.point_count - 1
	)

	return first_point_position.is_equal_approx(last_point_position)
