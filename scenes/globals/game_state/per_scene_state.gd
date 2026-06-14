# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PerSceneState
extends Resource
## State concerning the current scene in the game.
##
## This state is replaced whenever the game changes scene.

## Emitted when it becomes too dark that artificial lights can turn on, or
## when darkness goes away so artificial lights should turn off. If [param
## immediate] is true, this should take effect immediately; if false, artificial
## lights should turn on gradually.
signal lights_changed(lights_on: bool, immediate: bool)

## The path to the current scene.
@export var path: String

## Path to the current spawn point within the scene at [member path], or
## [code]^""[/code] if the player should spawn at the default position when
## reloading the scene.
@export var spawn_point: NodePath:
	set = set_spawn_point

## Set when any introductory dialogue has been played for the current scene.
@export var intro_dialogue_shown: bool

## Current state of artificial lights. Set with [member set_lights_on]. This is
## not saved to disk since the lights are controlled programmatically.
var lights_on: bool


func _init(scene_path: String = "") -> void:
	path = scene_path


## Change the state of [member lights_on]. If [param immediate] is [code]
func set_lights_on(new_value: bool, immediate: bool = false) -> void:
	# Annoyingly you can't use a method with a second optional parameter as a
	# property setter.
	lights_on = new_value
	lights_changed.emit(new_value, immediate)


func set_spawn_point(new_value: NodePath) -> void:
	spawn_point = new_value
	emit_changed()
