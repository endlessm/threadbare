# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ArtificialLightBehavior
extends Node
## @experimental
##
## Make the light automatically turn OFF during daytime and ON during nighttime,
## according to the game state, for energy-saving and cosmetic reasons.

## The controlled light.
@export var light: Light2D:
	set = _set_light

## Duration of the fading animations.
## [br][br]
## Although light travels super fast, a less abrupt effect is better to
## avoid affecting gameplay.
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:s") var fade_duration: float = 1.0

## If non-zero, a random delay between zero and this value will be prepended
## to the fading animations. This could add variation to multiple instances
## of the same component, like a house.
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:s") var random_delay: float = 0.0

var initial_energy: float
var tween: Tween


func _enter_tree() -> void:
	if not light and get_parent() is Light2D:
		light = get_parent()


func _set_light(new_light: Light2D) -> void:
	light = new_light
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not light:
		warnings.append("Light must be set.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	initial_energy = light.energy
	light.visible = GameState.lights_on
	light.enabled = GameState.lights_on
	GameState.lights_changed.connect(_on_lights_changed)


func _on_lights_changed(lights_on: bool, immediate: bool) -> void:
	if immediate:
		light.visible = lights_on
		light.enabled = lights_on
		light.energy = initial_energy if lights_on else 0.0
		return

	if lights_on:
		fade_in()
	else:
		fade_out()


func fade_in() -> void:
	if tween:
		tween.kill()
	tween = create_tween()

	light.energy = 0
	light.visible = true
	light.enabled = true
	if random_delay:
		tween.tween_interval(randf_range(0, random_delay))
	tween.tween_property(light, "energy", initial_energy, fade_duration)


func fade_out() -> void:
	if tween:
		tween.kill()
	tween = create_tween()

	var after_tween := func() -> void:
		light.visible = false
		light.enabled = false

	light.energy = initial_energy
	if random_delay:
		tween.tween_interval(randf_range(0, random_delay))
	tween.tween_property(light, "energy", 0, fade_duration)
	tween.tween_callback(after_tween)
