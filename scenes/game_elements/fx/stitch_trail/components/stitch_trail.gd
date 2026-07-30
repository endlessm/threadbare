# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name StitchTrail
extends Node2D
## @experimental
##
## A stitching effect for a [Line2D] node.
##
## Add points to the line in zigzag, imitating a thread being stitched.
## [br][br]
## Note: For the effect to be achieved, this node must move. For example, by putting it as child of
## a [PathFollow2D] node.

## The line to use for the effect.
@export var line: Line2D

## Flatten the effect vertically so it looks like it's on the floor, matching
## the Threadbare top-down isometric perspective.
@export var on_floor: bool = true

## How thick is the effect.
@export_range(0, 150, 1.0, "suffix:px") var width: float = 50

## How many stitches per second.
@export_range(0, 1, 0.01) var stitches_per_second: float = 0.03

## Weight of the direction lerp interpolation. To smooth the zigzag direction as this node moves.
## This wouldn't be necessary if moving along a predefined path. But if moving abruptly using the
## mouse position (for instance) this smoothing is better.
@export_range(0, 1, 0.01) var direction_weight: float = 0.1

## MANUQ TODO
@export var min_points_distance := 40

## How many points can the [member line] have.
@export var max_points := 100

var _last_stitch_seconds: float = 0
var _last_position: Vector2
var _stitch_direction: Vector2
var _stitch_sign := 1


func _do_stitch() -> void:
	var new_point := global_position + (_stitch_direction * width / 2) * _stitch_sign
	line.add_point(line.to_local(new_point))
	_stitch_sign *= -1
	_last_position = global_position


func _process(delta: float) -> void:
	if _last_stitch_seconds < stitches_per_second:
		_last_stitch_seconds += delta
		return
	_last_stitch_seconds = 0

	var direction := Vector2.ZERO if not _last_position else _last_position - global_position
	var orthogonal := direction.orthogonal().normalized()
	if on_floor:
		orthogonal *= Vector2(1, 0.5)
	_stitch_direction = _stitch_direction.lerp(orthogonal, direction_weight)

	if not line.get_point_count():
		_do_stitch()
	else:
		if _last_position.distance_squared_to(global_position) < min_points_distance:
			line.remove_point(0)
			return
		_do_stitch()
	while line.get_point_count() > max_points:
		line.remove_point(0)
