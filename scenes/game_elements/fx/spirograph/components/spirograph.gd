# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Spirograph
extends Node2D

@export var line: Line2D
@export_range(10, 50, 1, "or_greater", "or_less") var radius: float = 30
@export_range(0, 100, 1, "or_greater", "or_less") var max_vel: float = 50
@export_range(-45, 45, 0.1, "radians", "or_greater", "or_less") var wheel_rotation: float = 0.2
@export_range(0, 1, 0.01) var radius_update: float = 0.1
@export var min_points_distance := 40
@export var max_points := 100
@export var debug := false

var rot := 0.0
var d := 0.0
var last_pos: Vector2
var noise := FastNoiseLite.new()

@onready var wheel: Node2D = %Wheel
@onready var tip: Node2D = %Tip


func _ready() -> void:
	tip.position.x = radius
	rot = wheel_rotation
	noise.seed = 123
	noise.frequency = 0.0005


func _draw() -> void:
	if debug:
		draw_circle(Vector2.ZERO, tip.position.x, Color(1.0, 0.0, 0.0, 0.486))
		draw_line(Vector2.ZERO, tip.position.rotated(wheel.rotation), Color(1.0, 1.0, 0.0, 0.486))


func _process(_delta: float) -> void:
	var diff := Vector2.ZERO if not last_pos else last_pos - global_position
	last_pos = global_position

	var x: float = (max_vel - min(diff.length_squared(), max_vel)) / max_vel
	d = lerpf(d, x, radius_update)

	# var dx: float = noise.get_noise_1d(Time.get_ticks_msec() * 1) * 50 * d
	tip.position.x = radius * d  #  + dx

	wheel.rotate(rot * d * d)
	trail(tip.global_position)
	if debug:
		queue_redraw()


func trail(global_pos: Vector2) -> void:
	if not line.get_point_count():
		line.add_point(global_pos)
	else:
		var last_p := line.points[-1]
		if last_p.distance_squared_to(global_pos) < min_points_distance:
			line.remove_point(0)
			return
		line.add_point(global_pos)
	while line.get_point_count() > max_points:
		line.remove_point(0)
