# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MusicalRock
extends StaticBody2D

signal note_played

const NOTES: String = "ABCDEFG"

## Note
@export_enum("A", "B", "C", "D", "E", "F", "G") var note: String = "C"

@export var audio_stream: AudioStream

@onready var animated_sprite: AnimatedSprite2D = %Sprite
@onready var interact_area: InteractArea = %InteractArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _set(property: StringName, value: Variant) -> bool:
	return PropertyUtils.set_child_property(self, property, value)


func _get(property: StringName) -> Variant:
	return PropertyUtils.get_child_property(self, property)


func _get_property_list() -> Array[Dictionary]:
	return PropertyUtils.expose_children_property(self, "modulate", "AnimatedSprite2D")


func _ready() -> void:
	if not Engine.is_editor_hint():
		audio_stream_player_2d.stream = audio_stream


func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	play()
	interact_area.interaction_ended.emit()


func play() -> void:
	note_played.emit()
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
