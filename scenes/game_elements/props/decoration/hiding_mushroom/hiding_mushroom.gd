# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var hide_player: AudioStreamPlayer2D = $HideSound
@onready var reveal_player: AudioStreamPlayer2D = $RevealSound


func _hide() -> void:
	animated_sprite_2d.play(&"hide")
	hide_player.play()
	await animated_sprite_2d.animation_finished
	if animated_sprite_2d.animation == &"hide":
		animated_sprite_2d.visible = false


func _reveal() -> void:
	animated_sprite_2d.visible = true
	animated_sprite_2d.play(&"reveal")
	reveal_player.play()
	await animated_sprite_2d.animation_finished
	if animated_sprite_2d.animation == &"reveal":
		animated_sprite_2d.play(&"idle")


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_hide()


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_reveal()
