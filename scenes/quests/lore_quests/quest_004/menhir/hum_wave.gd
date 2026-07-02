# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var color: Color = Color(0.95, 0.85, 0.45, 0.8)

var _radius: float = 0.0:
	set(value):
		_radius = value
		queue_redraw()


func play(max_radius: float, grow_time: float) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_radius", max_radius, grow_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "color:a", 0.0, grow_time).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()


func _draw() -> void:
	if _radius <= 0.0:
		return
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, color, 3.0, true)
