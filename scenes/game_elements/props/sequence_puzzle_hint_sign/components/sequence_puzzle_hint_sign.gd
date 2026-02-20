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

## The animations which must be defined for [member sprite_frames].
## [code]idle[/code] is used when [member is_solved] is false;
## [code]solved[/code] is used when [member is_solved] is true.
##
## A [code]hint[/code] animation can be defined, which will be played when the player interacts with the sign.
const REQUIRED_ANIMATIONS: Array[StringName] = [&"idle", &"solved"]

## Animations for this object.
@export var sprite_frames: SpriteFrames:
	set = _set_sprite_frames

## If enabled, the sequence will be demonstrated when the player interacts with the sign.
@export var interact_demonstrates: bool = true:
	set(new_value):
		interact_demonstrates = new_value
		update_configuration_warnings()

## Whether the corresponding puzzle step has been solved.
@export var is_solved: bool = false:
	set(new_val):
		is_solved = new_val
		update_solved_state()

@export_group("Sounds")

## Optional sound when solved.
@export var solved_sound_effect: AudioStream

## Optional looping ambient sound when solved.
@export var solved_ambient_sound: AudioStream

## If true, the sign is interactive even when unsolved.
var interactive_hint: bool = false:
	set(new_value):
		interactive_hint = new_value
		update_solved_state()

## 🔴🩷🟢🟡 Custom color sequence for this sign
@export var color_sequence: Array[String] = ["red", "pink", "green", "yellow"]

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var solved_player: AudioStreamPlayer2D = %SolvedPlayer
@onready var solved_ambient_player: AudioStreamPlayer2D = %SolvedAmbientPlayer

func _ready() -> void:
	_set_sprite_frames(sprite_frames)
	_set_solved_sound_effect(solved_sound_effect)
	_set_solved_ambient_sound(solved_ambient_sound)
	update_solved_state()

func update_solved_state() -> void:
	var was_node_ready: bool = is_node_ready()
	if not was_node_ready:
		await ready
	animated_sprite.play(&"solved" if is_solved else &"idle")
	interact_area.disabled = not (
		demonstrate_sequence.has_connections() and (is_solved or interactive_hint)
	)
	solved_player.playing = is_solved and was_node_ready
	solved_ambient_player.playing = is_solved

## Mark this sign as solved.
func set_solved() -> void:
	is_solved = true

## 🔥 Player interaction: now includes color sequence display
func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	if sprite_frames.has_animation(&"hint"):
		animated_sprite.play(&"hint")

	# Display the color sequence in console
	print("Color sequence: ", color_sequence)

	# Optional: show the color sequence as text on screen
	_show_color_hint_on_screen()

	if interact_demonstrates and demonstrate_sequence.has_connections():
		demonstrate_sequence.emit()
	else:
		demonstration_finished()

## This function shows the color hint in the screen
func _show_color_hint_on_screen() -> void:
	var label := Label.new()
	label.text = " → ".join(color_sequence)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", 22)
	label.position = Vector2(200, 100)
	get_tree().root.add_child(label)
	
	# The text disappears after 3 seconds
	await get_tree().create_timer(3.0).timeout
	label.queue_free()

## Should be called when demonstration is complete.
func demonstration_finished() -> void:
	if animated_sprite.animation == &"hint":
		if animated_sprite.is_playing():
			await animated_sprite.animation_finished
		animated_sprite.play(&"solved" if is_solved else &"idle")
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
	var all_animations: Array[StringName] = REQUIRED_ANIMATIONS.duplicate()
	if not interact_demonstrates:
		all_animations.append(&"hint")
	for animation in all_animations:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
	return warnings
