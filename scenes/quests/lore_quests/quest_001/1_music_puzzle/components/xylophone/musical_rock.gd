# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MusicalRock
extends StaticBody2D

## Emitted when the rock is struck by the player.
signal note_played

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://7ul4p7v1ve0p")

## The animations which must be defined for [member sprite_frames]. The [code]default[/code]
## animation is used when the object is idle; [code]struck[/code] is used when the player interacts
## with the object.
const REQUIRED_ANIMATIONS: Array[StringName] = [&"default", &"struck"]

## Animations for this object. The SpriteFrames must have specific animations.
## See [constant MusicalRock.REQUIRED_ANIMATIONS].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames

@export var audio_stream: AudioStream

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAMES
	animated_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
	for animation in REQUIRED_ANIMATIONS:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
	return warnings


func _ready() -> void:
	_set_sprite_frames(sprite_frames)
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
