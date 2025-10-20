# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SequencePuzzleObject
extends StaticBody2D

## Emitted when the object is kicked by the player.
signal kicked

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://b41l3fs3yj2fc")

## The animations which must be defined for [member sprite_frames]. The [code]default[/code]
## animation is used when the object is idle; [code]struck[/code] is used when the player interacts
## with the object. Both animations should loop cleanly.
const REQUIRED_ANIMATIONS: Array[StringName] = [&"default", &"struck"]

## Animations for this object. The SpriteFrames must have specific animations.
## See [constant SequencePuzzleObject.REQUIRED_ANIMATIONS].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames

## Sound to play when the player strikes this object.
@export var audio_stream: AudioStream

## How long the [code]struck[/code] animation should play for when the object is struck by the
## player. This should typically be similar to the duration of [member audio_stream]. The player
## can interact with the object again even before this time has elapsed, but demonstrations of the
## sequence will wait for exactly this time before continuing to the next object.
@export_range(0.5, 1.5, 1.0 / 60, "or_less", "or_greater", "suffix:s")
var strike_duration: float = 1.0

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
	kicked.emit()
	play()
	interact_area.interaction_ended.emit()


## Act as if the object was kicked by the player, but dees not emit [member kicked].
func play(silent: bool = false) -> void:
	animated_sprite.play(&"struck")
	if not silent:
		audio_stream_player_2d.play()

	await get_tree().create_timer(strike_duration).timeout

	# Don't wait for the end of the animation loop, so that this method takes exactly
	# strike_duration seconds to resolved and a demo can be synced to an animation.
	_stop()


func _stop() -> void:
	if animated_sprite.is_playing() and animated_sprite.animation == "struck":
		await animated_sprite.animation_looped
		animated_sprite.play("default")


## Stop the silent hint animation, if playing.
func stop_hint() -> void:
	await _stop()
