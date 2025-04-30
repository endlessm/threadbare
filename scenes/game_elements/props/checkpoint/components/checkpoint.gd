# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Checkpoint
extends Area2D
## A place where the player respawns if the current scene is reloaded.

## The point where the player will spawn.
@onready var spawn_point: SpawnPoint = %SpawnPoint

## The sprite displayed when this checkpoint is activated
@onready var sprite: Sprite2D = %Sprite

## The collision shape for the sprite, when this checkpoint is activated
@onready var collision_shape: CollisionShape2D = %CollisionShape


func _ready() -> void:
	sprite.visible = false
	body_entered.connect(func(_body: Node2D) -> void: self.activate())


## Makes this the active checkpoint.
func activate() -> void:
	GameState.current_spawn_point = owner.get_path_to(spawn_point)
	sprite.visible = true
	collision_shape.set_deferred(&"disabled", false)
