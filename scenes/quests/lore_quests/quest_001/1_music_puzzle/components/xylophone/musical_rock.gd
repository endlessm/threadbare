# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name MusicalRock
extends StaticBody2D

## Emitted when the rock is struck by the player.
signal note_played

const NOTES: String = "ABCDEFG"

## Note
@export_enum("A", "B", "C", "D", "E", "F", "G") var note: String = "C"

@export var audio_stream: AudioStream

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _ready() -> void:
	audio_stream_player_2d.stream = audio_stream


func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	note_played.emit()
	play()
	interact_area.interaction_ended.emit()


## Act as if the rock was struck by the player. Does not emit [member note_played].
func play() -> void:
	animated_sprite.play(&"struck")
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	await animated_sprite.animation_looped
	animated_sprite.play(&"default")


func wobble_silently() -> void:
	animated_sprite.play(&"struck")
	await get_tree().create_timer(1.0).timeout
	stop_hint()


func stop_hint() -> void:
	if animated_sprite.is_playing() and animated_sprite.animation == "struck":
		await animated_sprite.animation_looped
		animated_sprite.play("default")
