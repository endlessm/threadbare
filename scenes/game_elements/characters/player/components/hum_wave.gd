# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HumWave
extends Node2D
## An expanding ring with a burst of particles, displayed when the player hums.

@export var color: Color = Color(0.502, 0.78, 1.0, 0.8)

## The radius the hum wave grows to.
@export_range(0.0, 1000.0, 1.0, "or_greater") var hum_wave_radius: float = 650.0

## The duration of the hum wave.
@export_range(0.0, 10.0, 0.1, "or_greater") var hum_wave_duration: float = 2.0

var _radius: float = 0.0:
	set(value):
		_radius = value
		queue_redraw()

@onready var burst: GPUParticles2D = %Burst
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var air_stream_collision: CollisionShape2D = %AirStreamCollision


func _ready() -> void:
	burst.emitting = true
	audio_stream_player_2d.play()
	air_stream_collision.disabled = false
	air_stream_collision.shape.radius = 0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_radius", hum_wave_radius, hum_wave_duration).set_ease(
		Tween.EASE_OUT
	)
	var property_name := "air_stream_collision:shape:radius"
	tween.tween_property(self, property_name, hum_wave_radius, hum_wave_duration).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(self, "color:a", 0.0, hum_wave_duration).set_ease(Tween.EASE_IN)
	await tween.finished
	#air_stream_collision.disabled = false
	#air_stream_collision.shape.radius = 0
	queue_free()


func _on_air_stream_body_entered(body: Node2D) -> void:
	if body.has_method("got_repelled"):
		var direction := global_position.direction_to(body.global_position)
		body.got_repelled(direction)


func _draw() -> void:
	if _radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, _radius, color, false, 3.0, true)
