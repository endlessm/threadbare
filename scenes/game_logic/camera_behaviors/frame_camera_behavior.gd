# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name FrameCameraBehavior
extends Node2D
## Pan a camera to frame a target.
##
## If the target is within a safe region, make the camera work as usual,
## centered in [member main_target], which is usually the camera parent node.
## [br][br]
## The safe region is defined by the [member target_drag_left_margin],
## [member target_drag_top_margin], [member target_drag_right_margin] and
## [member target_drag_bottom_margin] margins.
## [br][br]

## The controlled camera.
@export var camera: Camera2D:
	set = _set_camera

## The camera will be centered in this node if [member frame_target] is on frame.
## This will be set to the camera parent automatically, if not set.
@export var main_target: Node2D:
	set = _set_main_target

## The target to frame.
@export var frame_target: Node2D

## The [member Camera2D.drag_horizontal_enabled] when [member frame_target] is off frame.
@export var target_drag_horizontal_enabled := true

## The [member Camera2D.target_drag_vertical_enabled] when [member frame_target] is off frame.
@export var target_drag_vertical_enabled := true

## The [member Camera2D.target_drag_left_margin] when [member frame_target] is off frame.
## [br] Also defines the safe region.
@export var target_drag_left_margin := 0.5

## The [member Camera2D.target_drag_top_margin] when [member frame_target] is off frame.
## [br] Also defines the safe region.
@export var target_drag_top_margin := 0.5

## The [member Camera2D.target_drag_right_margin] when [member frame_target] is off frame.
## [br] Also defines the safe region.
@export var target_drag_right_margin := 0.5

## The [member Camera2D.target_drag_bottom_margin] when [member frame_target] is off frame.
## [br] Also defines the safe region.
@export var target_drag_bottom_margin := 0.5

## The safe region.
var safe_region_rect: Rect2

var _initial_drag_horizontal_enabled: bool
var _initial_drag_vertical_enabled: bool
var _initial_drag_left_margin: float
var _initial_drag_top_margin: float
var _initial_drag_right_margin: float
var _initial_drag_bottom_margin: float


func _enter_tree() -> void:
	if not camera and get_parent() is Camera2D:
		camera = get_parent()
	if not main_target and get_parent() and get_parent().get_parent() is Node2D:
		main_target = get_parent().get_parent()


func _set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
	update_configuration_warnings()


func _set_main_target(new_main_target: Node2D) -> void:
	main_target = new_main_target
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not camera:
		warnings.append("Camera must be set.")
	if not main_target:
		warnings.append("Consider setting Main Target.")
	if not frame_target:
		warnings.append("Consider setting Frame Target.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint() or not camera.enabled or not camera.is_current():
		set_process(false)

	if not Engine.is_editor_hint():
		_initial_drag_horizontal_enabled = camera.drag_horizontal_enabled
		_initial_drag_vertical_enabled = camera.drag_vertical_enabled
		_initial_drag_left_margin = camera.drag_left_margin
		_initial_drag_top_margin = camera.drag_top_margin
		_initial_drag_right_margin = camera.drag_right_margin
		_initial_drag_bottom_margin = camera.drag_bottom_margin

		safe_region_rect = _calculate_safe_region()


func _calculate_safe_region() -> Rect2:
	var camera_rect := Rect2(
		Vector2.ZERO,
		Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)
	)
	# Shrink the camera rect according to the margins defined.
	# A margin of 1 doesn't shrink, leaves the side in the same place.
	return (
		camera_rect
		. grow_individual(
			-1 * (1.0 - target_drag_left_margin) * camera_rect.size.x / 2,
			-1 * (1.0 - target_drag_top_margin) * camera_rect.size.y / 2,
			-1 * (1.0 - target_drag_right_margin) * camera_rect.size.x / 2,
			-1 * (1.0 - target_drag_bottom_margin) * camera_rect.size.y / 2,
		)
	)


func _process(_delta: float) -> void:
	if not frame_target:
		return

	var rect := Rect2(
		main_target.global_position - safe_region_rect.size / 2, safe_region_rect.size
	)

	if rect.has_point(frame_target.global_position):
		# The target is on frame, so set the camera initial settings
		# and the initial position.
		camera.global_position = main_target.global_position + position
		camera.drag_horizontal_enabled = _initial_drag_horizontal_enabled
		camera.drag_vertical_enabled = _initial_drag_vertical_enabled
		camera.drag_left_margin = _initial_drag_left_margin
		camera.drag_top_margin = _initial_drag_top_margin
		camera.drag_right_margin = _initial_drag_right_margin
		camera.drag_bottom_margin = _initial_drag_bottom_margin
	else:
		camera.global_position = frame_target.global_position
		camera.drag_horizontal_enabled = target_drag_horizontal_enabled
		camera.drag_vertical_enabled = target_drag_vertical_enabled
		camera.drag_left_margin = target_drag_left_margin
		camera.drag_top_margin = target_drag_top_margin
		camera.drag_right_margin = target_drag_right_margin
		camera.drag_bottom_margin = target_drag_bottom_margin
