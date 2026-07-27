# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CharacterAnimationPlayerBehavior
extends Node2D
## @experimental
##
## Play animations in [member animation_player] according
## to the velocity of [member character].
## [br][br]
## For creating simple characters, consider using [CharacterSpriteBehavior] instead.

## The [member CharacterBody2D.velocity] is used to change the [member animation_player].
## [br][br]
## [b]Note:[/b] If the grandparent node is a CharacterBody2D and this isn't set,
## the grandparent node will be automatically assigned to this variable.
@export var character: CharacterBody2D

## The controlled animation player.
## [br][br]
## [b]Note:[/b] If the parent node is an AnimationPlayer and this isn't set,
## the parent node will be automatically assigned to this variable.
@export var animation_player: AnimationPlayer:
	set = _set_animation_player

var _is_character_running: bool = false


func _enter_tree() -> void:
	if not animation_player and get_parent() is AnimationPlayer:
		animation_player = get_parent()
	if not character and get_parent() and get_parent().get_parent() is CharacterBody2D:
		character = get_parent().get_parent()


func _set_animation_player(new_animation_player: AnimationPlayer) -> void:
	animation_player = new_animation_player
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if animation_player is not AnimationPlayer:
		warnings.append("Animation Player must be set.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return


func _process(_delta: float) -> void:
	if not character:
		return

	if character.velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		if _is_character_running:
			animation_player.play(&"run")
		else:
			animation_player.play(&"walk")


## You can connect this callback to a [member InputWalkBehavior.running_changed] signal.
func on_running_changed(is_running: bool) -> void:
	_is_character_running = is_running
