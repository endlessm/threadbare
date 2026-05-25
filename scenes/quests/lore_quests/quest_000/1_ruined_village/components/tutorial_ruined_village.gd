# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
# Variables/methods in this file are accessed from dialogue.

@onready var tutorial_npc: CharacterBody2D = %TutorialNPC
@onready var bridge_blocker: StaticBody2D = %BridgeBlocker


func start_townie_walking() -> void:
	# Allow the player to cross the bridge
	bridge_blocker.collision_layer = 0

	tutorial_npc.walk_path()
