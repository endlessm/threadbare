# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RandomFrameSpriteBehavior
extends Node2D
## Starts a sprite animation from a random frame.
##
## The frame offset is not persisted to the owning scene.

## The controlled sprite.
## [br][br]
## [b]Note:[/b] If the parent node is a AnimatedSprite2D and this isn't set,
## the parent node will be automatically assigned to this variable.
@export var sprite: AnimatedSprite2D:
	set = _set_sprite


func _enter_tree() -> void:
	if not sprite and get_parent() is AnimatedSprite2D:
		sprite = get_parent()


func _set_sprite(new_sprite: AnimatedSprite2D) -> void:
	sprite = new_sprite
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if sprite is not AnimatedSprite2D:
		warnings.append("Sprite must be set.")
	return warnings


func _ready() -> void:
	var frames_length: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = randi_range(0, frames_length)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			sprite.frame_progress = 0
