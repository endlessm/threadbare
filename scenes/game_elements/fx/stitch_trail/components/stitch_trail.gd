# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name StitchTrail
extends Node2D
## @experimental
##
## MANUQ TODO
##
## MANUQ TODO

@export var line: Line2D
@export_range(0, 150, 1.0, "suffix:px") var width: float = 50
@export_range(0, 1, 0.01) var stitches_per_second: float = 0.03
@export_range(0, 1, 0.01) var direction_update: float = 0.1
@export var on_floor: bool = true
@export var min_points_distance := 40
@export var max_points := 100

var last_stitch_seconds: float = 0
var last_pos: Vector2
var stitch_direction: Vector2
var stitch_sign := 1


func _process(delta: float) -> void:
	var diff := Vector2.ZERO if not last_pos else last_pos - global_position
	var normal := diff.orthogonal().normalized()
	if on_floor:
		normal *= Vector2(1, 0.5)
	stitch_direction = lerp(stitch_direction, normal, direction_update)

	if last_stitch_seconds < stitches_per_second:
		last_stitch_seconds += delta
		return
	last_stitch_seconds = 0

	trail(global_position)


func trail(global_pos: Vector2) -> void:
	var new_p := global_position + (stitch_direction * width / 2) * stitch_sign
	if not line.get_point_count():
		line.add_point(line.to_local(new_p))
		stitch_sign *= -1
		last_pos = global_position
	else:
		if last_pos.distance_squared_to(global_pos) < min_points_distance:
			line.remove_point(0)
			return
		line.add_point(line.to_local(new_p))
		stitch_sign *= -1
		last_pos = global_position
	while line.get_point_count() > max_points:
		line.remove_point(0)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENABLED:
			last_pos = Vector2.ZERO
			last_stitch_seconds = 0
			stitch_direction = Vector2.ZERO
			stitch_sign = 1
