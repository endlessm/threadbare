# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const STORY_QUEST_CLOSING_TRANSITION = preload("./story_quest_closing_transition.dialogue")
const FRAYS_END_PATH = "res://scenes/world_map/frays_end.tscn"
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	animation_player.play("walk_into_scene")
	await animation_player.animation_finished
	DialogueManager.show_dialogue_balloon(STORY_QUEST_CLOSING_TRANSITION)
	await DialogueManager.dialogue_ended
	SceneSwitcher.change_to_file_with_transition(FRAYS_END_PATH)
