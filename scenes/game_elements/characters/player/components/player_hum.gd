# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name PlayerHum
extends Node2D

## Emitted when the hum starts.
signal hum_started

## If false, [member hum] should be called by other means.
@export var player_controlled: bool = true

## If controlled by the player, which input action triggers the hum.
@export var input_action: StringName = &"repel"

## The radius the hum wave grows to.
@export_range(0.0, 1000.0, 1.0, "or_greater") var hum_wave_radius: float = 650.0

## The duration of the hum wave.
@export_range(0.0, 10.0, 0.1, "or_greater") var hum_wave_duration: float = 2.0


## The scene to instantiate when spawning a hum wave. The scene's root node
## should be a [HumWave].
@export var hum_wave_scene: PackedScene:
	set(new_value):
		hum_wave_scene = new_value
		update_configuration_warnings()

## Time to wait until the next hum.
@onready var cooldown_timer: Timer = %CooldownTimer


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
	if not hum_wave_scene:
		warnings.append("The hum_wave_scene must be set")
	return warnings


func _unhandled_input(_event: InputEvent) -> void:
	if not player_controlled:
		return
	if Input.is_action_just_pressed(input_action):
		hum()


func hum() -> void:
	if not cooldown_timer.is_stopped():
		# TODO Add visual and audio clue that hum was attempted during cooldown time.
		return
	cooldown_timer.start()
	var hum_wave: HumWave = hum_wave_scene.instantiate()
	# TODO: Simplify parameters with a Resource
	hum_wave.hum_wave_radius = hum_wave_radius
	hum_wave.hum_wave_duration = hum_wave_duration
	hum_wave.global_position = global_position
	get_tree().current_scene.add_child(hum_wave)
	hum_started.emit()
	# TODO instantiate the hum wave in the scene.
