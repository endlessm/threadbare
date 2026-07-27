# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SavedGame
extends Resource

## Game-wide state
@export var global: GlobalState = GlobalState.new()

## State concerning the quest that the player is currently playing, or
## [code]null[/code] if they are not playing a quest.
@export var quest: QuestState

## State concerning the scene that the player is currently playing.
@export var scene: PerSceneState
