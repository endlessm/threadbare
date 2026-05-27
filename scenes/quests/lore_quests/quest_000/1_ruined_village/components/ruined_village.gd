# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
# Variables/methods in this file are accessed from dialogue.

@onready var townie_interact_area: InteractArea = %InteractArea
@onready var bridge_blocker: StaticBody2D = %BridgeBlocker
@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior


func is_townie_walking() -> bool:
	return townie_interact_area.disabled


func start_townie_walking() -> void:
	# Prevent talking a second time
	townie_interact_area.disabled = true
	# Allow the player to cross the bridge
	bridge_blocker.collision_layer = 0
	# Start the townie walking
	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
