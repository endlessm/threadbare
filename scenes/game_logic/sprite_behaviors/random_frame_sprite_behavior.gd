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
	# TODO: weight the choice of frame by the relative lengths of frames.
	# i.e. if an animation has one frame lasting 800ms, and four frames lasting 100ms each,
	# we should be 8× more likely to pick the 800ms frame than each of the other 4.
	sprite.set_frame_and_progress(randi_range(0, frames_length), randf())


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			sprite.frame = 0
