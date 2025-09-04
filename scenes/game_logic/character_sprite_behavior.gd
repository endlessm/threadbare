# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CharacterSpriteBehavior
extends Node2D
## @experimental
##
## Flip horizontally and/or play animations in [member sprite] according
## to the velocity of [member character].

## The [member CharacterBody2D.velocity] is used to change the [member sprite].
@export var character: CharacterBody2D

## Whether to play the sprite animations or not. If not, the only thing that will happen is that
## the sprite will be flipped horizontally according to the velocity of [member character].
## Use this when using more advanced animation through an AnimationPlayer node.
@export var play_animations: bool = true

## The controlled sprite.[br][br]
##
## [b]Note:[/b] If the parent node is a AnimatedSprite2D and sprite isn't set,
## the parent node will be automatically assigned to this variable.
@export var sprite: AnimatedSprite2D:
	set = _set_sprite

var _is_character_running: bool = false


func _enter_tree() -> void:
	if not sprite and get_parent() is AnimatedSprite2D:
		sprite = get_parent()


func _set_sprite(new_sprite: AnimatedSprite2D):
	sprite = new_sprite
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if sprite is not AnimatedSprite2D:
		warnings.append("Sprite must be set.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return


func _process(delta: float) -> void:
	if not character:
		return

	if play_animations:
		_process_animations(delta)

	if not is_zero_approx(character.velocity.x):
		sprite.flip_h = character.velocity.x < 0


func _process_animations(_delta: float) -> void:
	if character.velocity.is_zero_approx():
		sprite.speed_scale = 1.0
		sprite.play(&"idle")
	else:
		if _is_character_running:
			if sprite.sprite_frames.has_animation(&"run"):
				sprite.speed_scale = 1.0
				sprite.play(&"run")
			else:
				sprite.speed_scale = 2.0
				sprite.play(&"walk")
		else:
			sprite.speed_scale = 1.0
			sprite.play(&"walk")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# Since this is a tool script that plays the animations in the
			# editor, reset the frame progress before saving the scene.
			sprite.frame_progress = 0


## Force the sprite to flip to a [enum Enums.LookAtSide] direction.
func look_at_side(side: Enums.LookAtSide) -> void:
	if side == 0:
		return
	sprite.flip_h = side < 0


## You can connect this callback to a [member InputWalkBehavior.running_changed] signal.
func on_running_changed(is_running: bool) -> void:
	_is_character_running = is_running
