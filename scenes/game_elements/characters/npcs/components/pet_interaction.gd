# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

## The area to interact with the pet.
@export var interact_area: InteractArea

## Sound effect to play when interacted.
@export var sound_effect_player: AudioStreamPlayer2D

## If set, it will shake when interacted.
@export var shaker: Shaker

## If set, it will increment when interacted.
@export var fact_counter: FactCounter

## The sprite that plays the interaction animation.
@export var pet_animation: AnimatedSprite2D

## Controls the sprite animations based on the pet movement.
@export var pet_sprite_behavior: CharacterSpriteBehavior

## If set, it will modify the pet behavior when interacted with.
@export var interaction_behavior: Node

## The animation to play when interacted with.
@export var interaction_animation: StringName


func _ready() -> void:
	interact_area.interaction_started.connect(_on_interact_area_interaction_started)


func _on_interact_area_interaction_started(player: Player, _from_right: bool) -> void:
	interact_area.end_interaction()
	interact_area.disabled = true
	sound_effect_player.play()
	if shaker:
		shaker.shake()
	if fact_counter:
		fact_counter.increment()
	if interaction_behavior and interaction_behavior.has_method(&"apply"):
		interaction_behavior.apply(player, pet_animation)
	if interaction_animation:
		pet_sprite_behavior.set_process(false)
		pet_animation.play(interaction_animation)
		await pet_animation.animation_finished
		pet_animation.play(&"idle")
		pet_sprite_behavior.set_process(true)
	if sound_effect_player.playing:
		await sound_effect_player.finished
	interact_area.disabled = false
