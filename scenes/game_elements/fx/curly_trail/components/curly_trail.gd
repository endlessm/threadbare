# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CurlyTrail
extends Node2D
## @experimental
##
## A curly trail effect for a [Line2D] node.
##
## Add points to the line in circle, so when this node moves, a curly effect is obtained. The circle
## radius becomes smaller the faster this node moves, as a simple way to achieve a thread stretching
## effect.
## [br][br]
## Note: For the effect to be achieved, this node must move. For example, by putting it as child of
## a [PathFollow2D] node.

## The line to use for the effect.
@export var line: Line2D

## The radius at zero velocity.
@export_range(10, 50, 1, "or_greater", "or_less") var radius: float = 30

## The velocity at which the thread stretches fully.
@export_range(0, 100, 1, "or_greater", "or_less") var stretched_velocity: float = 50

@export_range(-45, 45, 0.1, "radians", "or_greater", "or_less") var wheel_rotation: float = 0.2
@export_range(0, 1, 0.01) var radius_update: float = 0.1
@export var min_points_distance := 40

## How many points can the [member line] have.
@export var max_points := 100

## Draw the wheel circle and the tip for debugging.
@export var debug := false

## A value between 0 and 1 that is how stretched is the line.
var _stretching_amount := 0.0

var _last_position: Vector2

@onready var wheel: Node2D = %Wheel
@onready var tip: Node2D = %Tip


func _ready() -> void:
	tip.position.x = radius


func _draw() -> void:
	if debug:
		draw_circle(Vector2.ZERO, tip.position.x, Color(1.0, 0.0, 0.0, 0.486))
		draw_line(Vector2.ZERO, tip.position.rotated(wheel.rotation), Color(1.0, 1.0, 0.0, 0.486))


func _process(_delta: float) -> void:
	var direction := Vector2.ZERO if not _last_position else _last_position - global_position
	_last_position = global_position

	var new_stretching_amount: float = (
		(stretched_velocity - min(direction.length_squared(), stretched_velocity))
		/ stretched_velocity
	)
	_stretching_amount = lerpf(_stretching_amount, new_stretching_amount, radius_update)

	tip.position.x = radius * _stretching_amount
	wheel.rotate(wheel_rotation * _stretching_amount * _stretching_amount)

	if not line.get_point_count():
		line.add_point(line.to_local(tip.global_position))
	else:
		var last_p := line.points[-1]
		if last_p.distance_squared_to(tip.global_position) < min_points_distance:
			line.remove_point(0)
			return
		line.add_point(line.to_local(tip.global_position))
	while line.get_point_count() > max_points:
		line.remove_point(0)

	if debug:
		queue_redraw()
