# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Cinematic
extends SceneLink
## Shows a dialogue, then transitions to another scene.
##
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest.
## It can also be used as an easy way to display dialogue at the beginning of a level.

## Emitted when the cinematic has finished. Use it if not passing [member next_scene]
## when you need to do something else after the cinematic.
signal cinematic_finished

## Dialogue for cinematic scene.
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Optional animation player, to be used from [member dialogue] (if needed).
@export var animation_player: AnimationPlayer

## Wether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	super._ready()

	if autostart:
		start()


func start() -> void:
	if not GameState.intro_dialogue_shown:
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		GameState.intro_dialogue_shown = true

	cinematic_finished.emit()
	switch()
