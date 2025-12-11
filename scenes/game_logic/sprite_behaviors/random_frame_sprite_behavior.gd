# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RandomFrameSpriteBehavior
extends BaseSpriteBehavior
## Starts a sprite animation from a random frame.
##
## The frame offset is not persisted to the owning scene.


func _ready() -> void:
	var frames_length: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = randi_range(0, frames_length)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			sprite.frame_progress = 0
