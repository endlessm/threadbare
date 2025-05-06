# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Decoration

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://d36eq8tqdaxdy")

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play(animated_sprite_2d.animation)


func _ready() -> void:
	_set_sprite_frames(sprite_frames)
	var frames_length: int = animated_sprite_2d.sprite_frames.get_frame_count(
		animated_sprite_2d.animation
	)
	animated_sprite_2d.frame = randi_range(0, frames_length)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		var y_scale := randf_range(0.8, 1.2)
		var x_scale := y_scale * randf_range(0.9, 1.1)
		scale = Vector2(x_scale, y_scale)
