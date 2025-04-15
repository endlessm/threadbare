# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## Shows a dialogue, then transitions to another scene.
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest
class_name Cinematic
extends Node2D

## Dialogue for cinematic scene
@export var dialogue: DialogueResource = preload(
	"res://scenes/ui_elements/cinematic/cinematic_placeholder.dialogue"
)

## Animation player, to be used from [member dialogue] (if needed)
@export var animation_player: AnimationPlayer

## Scene to switch to once [member dialogue] is complete
@export_file("*.tscn") var next_scene: String


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended

	if next_scene:
		SceneSwitcher.change_to_file_with_transition(
			next_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)
