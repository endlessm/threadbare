# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var arrow: PackedScene
@export var time: float = 1.0

@onready var cooldown: Timer = $Cooldown


## Sets the cooldown timer.
func _ready() -> void:
	cooldown.wait_time = time


## Spawns in the arrows.
func shoot() -> void:
	var arr: Node = arrow.instantiate()
	arr.spawn_pos = global_position
	owner.add_child(arr)


## When the timer runs out, spawn an arrow.
func _on_cooldown_timeout() -> void:
	shoot()
