# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## How fast the sheep and townie run.
@export var speed: float = 180

## How long the sheep's head start is.
@export var head_start: float = 1.5

var sheep_sprite: AnimatedSprite2D

@onready var sheep_path_follow: CharacterBody2D = %SheepPathFollow
@onready var sheep_path_walk_behavior: PathWalkBehavior = %SheepPathWalkBehavior
@onready var townie_path_walk_behavior: PathWalkBehavior = %TowniePathWalkBehavior


func _ready() -> void:
	sheep_sprite = sheep_path_follow.get_node("AnimatedSprite2D")
	# TODO: Give sheep a walk animation
	sheep_path_walk_behavior.speeds.walk_speed = speed

	# Give the sheep a head start!
	await get_tree().create_timer(head_start).timeout

	townie_path_walk_behavior.speeds.walk_speed = speed


## Update the direction sheep sprite faces based on velocity.
func _process(_delta: float) -> void:
	sheep_sprite.flip_h = sheep_path_follow.velocity.x < 0
