# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends AnimatedSprite2D
## Starts a decoration's animation from a random frame.
##
## The frame offset is not persisted to the owning scene.


func _ready() -> void:
	var frames_length: int = sprite_frames.get_frame_count(animation)
	frame = randi_range(0, frames_length)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			frame_progress = 0
