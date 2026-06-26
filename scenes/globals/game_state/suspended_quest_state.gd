# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SuspendedQuestState
extends Resource
## [QuestState] and [PerSceneState] for a quest that was started then abandoned.

@export var quest: QuestState
@export var scene: PerSceneState


func _init(quest_state: QuestState = null, scene_state: PerSceneState = null) -> void:
	quest = quest_state
	scene = scene_state
