# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Cinematic

@export var slider: TextureRect
@export var slider_frames: SpriteFrames
@export var slider_animation: StringName = &"default"

var _slider_frame: int = 0


func _ready() -> void:
	_show_slider_frame(0)
	super._ready()


func advance_frame() -> void:
	_show_slider_frame(_slider_frame + 1)


func _show_slider_frame(index: int) -> void:
	if (
		not slider
		or not slider_frames
		or not slider_frames.has_animation(slider_animation)
		or index < 0
		or index >= slider_frames.get_frame_count(slider_animation)
	):
		return

	_slider_frame = index
	slider.texture = slider_frames.get_frame_texture(slider_animation, index)
