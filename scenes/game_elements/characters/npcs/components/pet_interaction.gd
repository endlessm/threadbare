# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name PetInteraction
extends Node
## A simple "no code" way to react to an interaction.
##
## - Play a sound effect.[br]
## - Play an animation.[br]
## - Shake.[br]
## - Increment a fact counter.[br][br]
##
## The interact area will be re-enabled after the sound or animation (or both) finish playing.

## The area to interact with the pet.
@export var interact_area: InteractArea

## If set, this sound effect will play when interacted.
@export var sound_effect_player: AudioStreamPlayer2D

## If set, it will play the [code]"pet"[/code] animation when interacted.
@export var animated_sprite: AnimatedSprite2D:
	set = _set_animated_sprite

## If set, it will shake when interacted.
@export var shaker: Shaker

## If set, it will increment when interacted.
@export var fact_counter: FactCounter

## Behaviors to disable during the interaction.
## When the interaction ends, they will go back to their previous
## [member Node.process_mode].
@export var behaviors_to_disable: Array[Node]

var _previous_behavior_modes: Dictionary[Node, Node.ProcessMode]


func _set_animated_sprite(new_animated_sprite: AnimatedSprite2D) -> void:
	animated_sprite = new_animated_sprite
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if (
		animated_sprite
		and not (
			animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(&"pet")
		)
	):
		warnings.append("animated_sprite is missing the following animation: pet")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interact_area.interaction_started.connect(_on_interact_area_interaction_started)


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	interact_area.end_interaction()
	interact_area.disabled = true
	for behavior in behaviors_to_disable:
		_previous_behavior_modes[behavior] = behavior.process_mode
		behavior.process_mode = Node.PROCESS_MODE_DISABLED
	if sound_effect_player:
		sound_effect_player.finished.connect(_on_sound_effect_player_finished, CONNECT_ONE_SHOT)
		sound_effect_player.play()
	if animated_sprite:
		animated_sprite.animation_finished.connect(
			_on_animated_sprite_animation_finished, CONNECT_ONE_SHOT
		)
		animated_sprite.play(&"pet")
	if shaker:
		shaker.shake()
	if fact_counter:
		fact_counter.increment()


func _check_finished() -> void:
	if (
		sound_effect_player
		and sound_effect_player.finished.is_connected(_on_sound_effect_player_finished)
	):
		return
	if (
		animated_sprite
		and animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished)
	):
		return
	if animated_sprite:
		animated_sprite.play(&"idle")

	for behavior in behaviors_to_disable:
		behavior.process_mode = _previous_behavior_modes[behavior]

	interact_area.disabled = false


func _on_sound_effect_player_finished() -> void:
	_check_finished()


func _on_animated_sprite_animation_finished() -> void:
	_check_finished()
