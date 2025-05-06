# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Decoration

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	var frames_length: int = animated_sprite_2d.sprite_frames.get_frame_count(
		animated_sprite_2d.animation
	)
	animated_sprite_2d.frame = randi_range(0, frames_length)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		var y_scale := randf_range(0.8, 1.2)
		var x_scale := y_scale * randf_range(0.9, 1.1)
		scale = Vector2(x_scale, y_scale)
