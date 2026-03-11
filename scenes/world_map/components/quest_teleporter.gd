# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name QuestTeleporter
extends Area2D

const QUEST_SEPARATOR = preload("uid://c0fdh0ttv7brl")

## Scene to switch to when the player enters this teleport. If empty, the player
## will teleport within the current scene, to the position specified by [member
## spawn_point_path].
@export var quest: Quest:
	set(new_value):
		quest = new_value
		notify_property_list_changed()

## Which [SpawnPoint] (in the current scene) to place the player-character at if
## the player abandons the quest.
@export var abandon_spawn_point: SpawnPoint

@export_group("Transition")

## Transition to use when the player enters this teleporter. The transition on
## the far side is always FADE.
@export var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)

	if Engine.is_editor_hint():
		notify_property_list_changed()
		return

	self.body_entered.connect(_on_body_entered, CONNECT_ONE_SHOT)


func _on_body_entered(_body: PhysicsBody2D) -> void:
	if not quest:
		return

	var scene := get_tree().current_scene
	var abandon_point_path := scene.get_path_to(abandon_spawn_point)
	GameState.start_quest(quest, scene.scene_file_path, abandon_point_path)
	(
		SceneSwitcher
		. change_to_packed_with_transition(
			QUEST_SEPARATOR,
			"",
			enter_transition,
			Transition.Effect.FADE,
		)
	)
