# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerRepel
extends Node2D

## Emitted when the repel starts or stops.
signal repelling_changed(repelling: bool)

const REPEL_ANTICIPATION_TIME: float = 0.3

const HUM_WAVE_SCENE: PackedScene = preload(
	"res://scenes/game_elements/characters/player/components/hum_wave.tscn"
)
const HUM_WAVE_DURATION: float = 0.3

## If false, [member repelling] should be changed by other means.
@export var player_controlled: bool = true

## If controlled by the player, which input action triggers the repel.
@export var input_action: StringName = &"repel"

## Current state of the repel.
@export var repelling: bool = false:
	set = _set_repelling

@export_group("Hum")
## If true, every repel also hums: a sound and a wave are played.
## [br][br]
## The player enables this when it has the
## [constant Enums.PlayerAbilities.ABILITY_A_MODIFIER_1] ability.
@export var hum_enabled: bool = false

## The sound to play when humming.
@export var hum_sound: AudioStream = preload(
	"res://scenes/game_elements/characters/player/components/humEffect.wav"
)

## The radius the hum wave grows to.
@export_range(0.0, 500.0, 1.0, "or_greater") var hum_wave_radius: float = 150.0

@onready var air_stream: Area2D = %AirStream
@onready var repel_animation: AnimationPlayer = %RepelAnimation


func _set_repelling(new_repelling: bool) -> void:
	repelling = new_repelling
	if not is_node_ready():
		return
	repelling_changed.emit(repelling)
	if repelling:
		_animate()


func _unhandled_input(_event: InputEvent) -> void:
	if not player_controlled:
		return
	if Input.is_action_just_pressed(input_action):
		repelling = true
	elif Input.is_action_just_released(input_action):
		repelling = false


func repel_once() -> void:
	repelling = true
	repelling = false


func _on_air_stream_body_entered(body: Node2D) -> void:
	if body.has_method("got_repelled"):
		var direction := global_position.direction_to(body.global_position)
		body.got_repelled(direction)


## Play the hum sound and wave, if [member hum_enabled].
## [br][br]
## This is called by the repel animation, at the moment the air stream is released.
func hum() -> void:
	if not hum_enabled:
		return

	var wave: HumWave = HUM_WAVE_SCENE.instantiate()
	add_child(wave)
	wave.play(hum_wave_radius, HUM_WAVE_DURATION)

	var sound := AudioStreamPlayer2D.new()
	sound.stream = hum_sound
	sound.bus = &"SFX"
	add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)


func _animate() -> void:
	# The repel animation is already ongoing. Prevent starting it again by smashing the buttons.
	if repel_animation.current_animation == &"repel":
		return

	# Repel animation is being played for the first time. So skip the anticipation and go
	# directly to the action.
	repel_animation.play(&"repel")
	repel_animation.seek(REPEL_ANTICIPATION_TIME, false, false)


func _on_repel_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"repel" and repelling:
		repel_animation.play(&"repel")
