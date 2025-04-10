# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

const NEXT_SCENE: PackedScene = preload("res://scenes/world_map/frays_end.tscn")

## Dialogue introducing the world
@export
var introduction: DialogueResource = preload("res://scenes/menus/intro/components/intro.dialogue")

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.show_dialogue_balloon(introduction, "", [self])


func start_fade() -> void:
	animation_player.play(&"introduction")


func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	SceneSwitcher.change_to_packed_with_transition(
		NEXT_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
