# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SequencePuzzleHintSign
extends StaticBody2D

## Emitted when the player has interacted with the sign, expecting a demonstration of the sequence.
## The handler should call
## [method SequencePuzzleHintSign.demonstration_finished] when the demonstration is complete.
signal demonstrate_sequence

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://b5pj1pt7r6hdg")

## The animations which must be defined for [member sprite_frames]. The [code]idle[/code]
## animation is used when [member is_ignited] is false;
## [code]solved[/code] is used when [member is_ignited] is true.
## Optionally, a [code]hint[/code] animation can be defined, which will be played when the player
## interacts with the sign to see a demonstration of the sequence.
const REQUIRED_ANIMATIONS: Array[StringName] = [&"idle", &"solved"]

## Animations for this object. The SpriteFrames must have specific animations.
## See [constant SequencePuzzleHintSign.REQUIRED_ANIMATIONS].
@export var sprite_frames: SpriteFrames:
	set = _set_sprite_frames

@export var is_ignited: bool = false:
	set(new_val):
		is_ignited = new_val
		update_ignited_state()

@export_group("Sounds")

## An optional sound effect, played at the moment the corresponding puzzle step is solved.
## This should typically not loop.
@export var solved_sound_effect: AudioStream

## An optional sound effect, played continuously when the corresponding puzzle step has been solved.
## This should typically loop.
@export var solved_ambient_sound: AudioStream

## If true, the sign is interactive even when [member is_ignited] is [code]false[/code], allowing
## the player to see a demo of the corresponding sequence before solving it. Otherwise, the sign is
## only interactive once ignited.
var interactive_hint: bool = false:
	set(new_value):
		interactive_hint = new_value
		update_ignited_state()

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea

@onready var solved_player: AudioStreamPlayer2D = %SolvedPlayer
@onready var solved_ambient_player: AudioStreamPlayer2D = %SolvedAmbientPlayer


func _ready() -> void:
	_set_sprite_frames(sprite_frames)
	_set_solved_sound_effect(solved_sound_effect)
	_set_solved_ambient_sound(solved_ambient_sound)
	update_ignited_state()


func update_ignited_state() -> void:
	var was_node_ready: bool = is_node_ready()
	if not was_node_ready:
		await ready
	animated_sprite.play(&"solved" if is_ignited else &"idle")
	interact_area.disabled = not (
		demonstrate_sequence.has_connections() and (is_ignited or interactive_hint)
	)
	## We don't want to play the fire start sound if the bonfire started on.
	solved_player.playing = is_ignited and was_node_ready
	solved_ambient_player.playing = is_ignited


func ignite() -> void:
	is_ignited = true


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	if sprite_frames.has_animation(&"hint"):
		animated_sprite.play(&"hint")

	if demonstrate_sequence.has_connections():
		demonstrate_sequence.emit()
	else:
		demonstration_finished()


## Should be called by the handler of [signal demonstrate_sequence] when the demonstration is
## complete.
func demonstration_finished() -> void:
	if animated_sprite.animation == &"hint":
		if animated_sprite.is_playing():
			await animated_sprite.animation_finished

		animated_sprite.play(&"solved" if is_ignited else &"idle")

	interact_area.end_interaction()


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	if not new_sprite_frames:
		new_sprite_frames = DEFAULT_SPRITE_FRAMES
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	animated_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _set_solved_sound_effect(new_sound: AudioStream) -> void:
	if not is_node_ready():
		return

	solved_sound_effect = new_sound
	solved_player.stream = new_sound
	update_configuration_warnings()


func _set_solved_ambient_sound(new_sound: AudioStream) -> void:
	if not is_node_ready():
		return

	solved_ambient_sound = new_sound
	solved_ambient_player.stream = new_sound
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	for animation in REQUIRED_ANIMATIONS:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	return warnings
