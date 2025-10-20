# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@icon("uid://bu40b1xklo2g2")
class_name DirectionalInput
extends Node

@export_group("Action Bindings")
@export var action_up: StringName = "move_up"
@export var action_down: StringName = "move_down"
@export var action_left: StringName = "move_left"
@export var action_right: StringName = "move_right"

@export_group("Behavior")
## If true, will alternate between diagonals when held. Else, will repeat the most recent direction
@export var alternate_diagonals: bool = true
## If bigger than 0, will auto-repeat after a delay presses when inputs are held
@export var auto_repeat_delay: float = 0.2

var enabled: bool = true:
	set = set_enabled
var input: Callable

var _last_accepted_direction := Vector2i.ZERO
var _repeat_direction_h := Vector2i.ZERO
var _repeat_direction_v := Vector2i.ZERO
var _time_until_next_repeat: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	# Handle newly-pressed input directions
	if event.is_action_pressed(action_up):
		_input_immediately(Vector2i.UP)
		# Repeat if action is held
		_repeat_direction_v = Vector2i.UP
	elif event.is_action_pressed(action_down):
		_input_immediately(Vector2i.DOWN)
		# Repeat if action is held
		_repeat_direction_v = Vector2i.DOWN
	elif event.is_action_pressed(action_left):
		_input_immediately(Vector2i.LEFT)
		# Repeat if action is held
		_repeat_direction_h = Vector2i.LEFT
	elif event.is_action_pressed(action_right):
		_input_immediately(Vector2i.RIGHT)
		# Repeat if action is held
		_repeat_direction_h = Vector2i.RIGHT

	# Clear repeat directions upon input release
	if event.is_action_released(action_up) and _repeat_direction_v == Vector2i.UP:
		_repeat_direction_v = Vector2i.ZERO
	if event.is_action_released(action_down) and _repeat_direction_v == Vector2i.DOWN:
		_repeat_direction_v = Vector2i.ZERO
	if event.is_action_released(action_left) and _repeat_direction_h == Vector2i.LEFT:
		_repeat_direction_h = Vector2i.ZERO
	if event.is_action_released(action_right) and _repeat_direction_h == Vector2i.RIGHT:
		_repeat_direction_h = Vector2i.ZERO


func _process(delta: float) -> void:
	# Count down until repeat input
	if _time_until_next_repeat > 0.0:
		_time_until_next_repeat -= delta
		# Repeat timer reached 0
		if _time_until_next_repeat <= 0.0:
			repeat()


func _input_immediately(direction: Vector2i) -> bool:
	if not enabled:
		return false

	if not input:
		return false

	if not input.call(direction):
		return false

	_last_accepted_direction = direction

	if auto_repeat_delay > 0.0:
		_time_until_next_repeat += auto_repeat_delay

	return true


func _stop_movement() -> void:
	_last_accepted_direction = Vector2i.ZERO


func repeat() -> void:
	if alternate_diagonals:
		_repeat_alternate_diagonals()
	else:
		_repeat_latest_direction()


func _repeat_alternate_diagonals() -> void:
	# Last direction was horizontal and there's a vertical direction held
	if (
		_repeat_direction_v != Vector2i.ZERO
		and (
			_last_accepted_direction == Vector2i.LEFT or _last_accepted_direction == Vector2i.RIGHT
		)
		and _input_immediately(_repeat_direction_v)
	):
		return
	# Last direction was vertical and there's a horizontal direction held
	if (
		_repeat_direction_h != Vector2i.ZERO
		and (_last_accepted_direction == Vector2i.UP or _last_accepted_direction == Vector2i.DOWN)
		and _input_immediately(_repeat_direction_h)
	):
		return
	# There's a vertical direction held
	if _repeat_direction_v != Vector2i.ZERO and _input_immediately(_repeat_direction_v):
		return
	# There's a horizontal direction held
	if _repeat_direction_h != Vector2i.ZERO and _input_immediately(_repeat_direction_h):
		return
	# No directions held, so stop
	_stop_movement()


func _repeat_latest_direction() -> void:
	# Last direction was horizontal and it's still held
	if _last_accepted_direction == _repeat_direction_h and _input_immediately(_repeat_direction_h):
		return
	# Last direction was vertical and it's still held
	if _last_accepted_direction == _repeat_direction_v and _input_immediately(_repeat_direction_v):
		return
	# There's a vertical direction held
	if _repeat_direction_v != Vector2i.ZERO and _input_immediately(_repeat_direction_v):
		return
	# There's a horizontal direction held
	if _repeat_direction_h != Vector2i.ZERO and _input_immediately(_repeat_direction_h):
		return
	# No directions held, so stop
	_stop_movement()


func set_enabled(value: bool) -> void:
	if enabled == value:
		return

	enabled = value

	if not enabled:
		_last_accepted_direction = Vector2i.ZERO
		_repeat_direction_h = Vector2i.ZERO
		_repeat_direction_v = Vector2i.ZERO
