# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@export var speed = 300.0

var spawn_pos: Vector2


## Sets the spawn position of the arrow.
func _ready() -> void:
	global_position = spawn_pos


## Moves the arrow.
func _physics_process(_delta: float) -> void:
	velocity = Vector2(0, speed)
	move_and_slide()


## When the player is hit by the arrow, destroy the player.
func _on_hitbox_body_entered(body: Node2D) -> void:
	queue_free()
	if body.is_in_group("player"):
		body.defeat()


## If the timer runs out, delete the arrow from the scene to avoid lag.
func _on_duration_timer_timeout() -> void:
	queue_free()
