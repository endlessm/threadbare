# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool

## Make the character walk along a path.
##
## If the path is closed the character walks in circles. If not, they walk back and forth turning
## around in endings.
##
## If the character gets stuck while walking the path, they turn around.
##
## The character can wait standing in the path "pointy" points of the path.
class_name CanWalkAlongPath
extends Node2D

## Emitted when [member character] got stuck while walking the path.
signal got_stuck

## Emitted when turning around.
signal direction_changed

## Emitted when the character waits standing.
signal wait_standing_started

## Emitted when the character stops waiting standing.
signal wait_standing_finished

@export var walking_path: Path2D:
	set = _set_walking_path

## The character walking speed.
@export_range(5, 300, 5, "or_greater", "or_less", "suffix:m/s") var walk_speed: float = 100.0

## The wait time at each standing point. Set it to zero for no standing.
@export_range(0, 5, 0.1, "or_greater", "suffix:s") var standing_time: float = 1.0

## Enable it to also wait when the character gets stuck.
@export var wait_when_stuck: bool = false

## Make the "is stuck" calculation more or less sensitive.
@export_range(0.1, 1000, 5, "or_greater", "suffix:m²") var stuck_tolerance: float = 400.0

## Make the "is path continuous" calculation more or less sensitive.
@export_range(0, 100, 0.01, "or_greater", "suffix:m") var path_continuous_tolerance: float = 0.01

## Make the "is path pointy" calculation more or less sensitive.
@export_range(0, 1000, 1, "or_greater", "suffix:m²") var path_pointy_tolerance: float = 20

# Position of the first point relative to the path position.
var _initial_position: Vector2

# Timer used for the character to wait standing.
var _standing_timer: Timer = Timer.new()

# This is 1 when walking in the path direction, and -1 when walking in the opposite direction.
var _direction: int = 1:
	set = _set_direction

# Offset of each point that the character will wait standing.
var _standing_offsets: Array[float]

# TODO: Add configuration warning to the node if the parent is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	print("%s: I can walk along a path" % character.name)

	_set_walking_path(walking_path)

	_standing_timer.wait_time = standing_time
	_standing_timer.timeout.connect(_on_standing_timeout)
	_standing_timer.one_shot = true
	add_child(_standing_timer)

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

	if not character.is_node_ready():
		await character.ready
	character.animated_sprite_2d.play(&"walk")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENABLED:
			character.animated_sprite_2d.play(&"walk")
		NOTIFICATION_DISABLED:
			pass


func _draw() -> void:
	if Engine.is_editor_hint() or not get_tree().is_debugging_collisions_hint():
		return
	draw_circle(to_local(character.position), 15., Color(1.0, 0.0, 0.0, 0.4))


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	update_configuration_warnings()
	if not is_node_ready():
		return
	if walking_path:
		# Set initial position and put character in path:
		_initial_position = walking_path.position + walking_path.curve.get_point_position(0)
		character.position = _initial_position


func _set_direction(new_direction: int) -> void:
	_direction = signi(new_direction)
	if not is_node_ready():
		return
	direction_changed.emit()


func _get_configuration_warnings() -> PackedStringArray:
	if not walking_path:
		return ["A walking path must be set."]
	return []


## Return true if the end of the path is the same point as the beginning.
func _is_path_closed() -> bool:
	if walking_path.curve.point_count < 3:
		return false

	var first_point_position: Vector2 = walking_path.curve.get_point_position(0)
	var last_point_position: Vector2 = walking_path.curve.get_point_position(
		walking_path.curve.point_count - 1
	)

	return first_point_position.is_equal_approx(last_point_position)


func _start_wait_standing() -> void:
	character.animated_sprite_2d.play(&"idle")
	_standing_timer.start()
	wait_standing_started.emit()


func _physics_process(delta: float) -> void:
	if not _standing_timer.is_stopped():
		return

	var closest_offset := walking_path.curve.get_closest_offset(
		character.position - _initial_position + walking_path.curve.get_point_position(0)
	)
	var new_offset := closest_offset + walk_speed * delta * _direction

	for idx in range(_standing_offsets.size()):
		var point_offset = _standing_offsets[idx]

		if _direction == 1:
			if (
				point_offset > closest_offset
				and (point_offset < new_offset or is_equal_approx(point_offset, new_offset))
			):
				_start_wait_standing()
			elif new_offset > walking_path.curve.get_baked_length():
				_start_wait_standing()
		elif _direction == -1:
			if (
				point_offset < closest_offset
				and (point_offset > new_offset or is_equal_approx(point_offset, new_offset))
			):
				_start_wait_standing()
	if not _is_path_closed():
		# Turn around in endings:
		if new_offset > walking_path.curve.get_baked_length() or new_offset < 0.0:
			_direction *= -1

	var target_position := (
		_initial_position
		+ walking_path.curve.sample_baked(new_offset)
		- walking_path.curve.get_point_position(0)
	)
	character.velocity = character.position.direction_to(target_position) * walk_speed
	character.move_and_slide()

	var collision: KinematicCollision2D = character.get_last_slide_collision()

	# If the distance that was able to travel is lower than the remainder, we assume that the
	# character is stuck:
	if (
		collision
		and (
			collision.get_travel().length_squared()
			< collision.get_remainder().length_squared() / stuck_tolerance
		)
	):
		_direction *= -1
		got_stuck.emit()
		if wait_when_stuck:
			_start_wait_standing()

	if not is_zero_approx(character.velocity.x):
		character.look_at_side = (
			Enums.LookAtSide.LEFT if character.velocity.x < 0 else Enums.LookAtSide.RIGHT
		)


func _on_standing_timeout() -> void:
	character.animated_sprite_2d.play(&"walk")
	wait_standing_finished.emit()
