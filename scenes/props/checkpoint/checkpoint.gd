# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Checkpoint extends Area2D

## A place where the player respawns if the current scene is reloaded.

## The point where the player will spawn.
@onready var spawn_point: SpawnPoint = %SpawnPoint


func _ready() -> void:
	body_entered.connect(func(_body: Node2D) -> void: self.activate())


## Makes this the active checkpoint.
func activate() -> void:
	GameState.current_spawn_point = owner.get_path_to(spawn_point)
