# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name MusicalRock
extends StaticBody2D

signal note_played

const NOTES: String = "ABCDEFG"

## Note
@export_enum("A", "B", "C", "D", "E", "F", "G") var note: String = "C":
	set(_new_value):
		note = _new_value
		_modulate_rock()

@export var audio_stream: AudioStream

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_modulate_rock()
	audio_stream_player_2d.stream = audio_stream


func _modulate_rock() -> void:
	if animated_sprite:
		var i: int = NOTES.find(note)
		animated_sprite.modulate = Color.from_hsv(i * 100.0 / NOTES.length(), 0.67, 0.89)


func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	play()
	interact_area.interaction_ended.emit()


func play() -> void:
	note_played.emit()
	animated_sprite.play(&"struck")
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	animated_sprite.play(&"default")


func wobble_silently() -> void:
	animated_sprite.play(&"struck")
	await get_tree().create_timer(1.0).timeout
	stop_hint()


func stop_hint() -> void:
	if animated_sprite.is_playing() and animated_sprite.animation == "struck":
		animated_sprite.play("default")
