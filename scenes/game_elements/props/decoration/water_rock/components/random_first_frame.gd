# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


func _ready() -> void:
	frame = randi_range(0, sprite_frames.get_frame_count(animation) - 1)
