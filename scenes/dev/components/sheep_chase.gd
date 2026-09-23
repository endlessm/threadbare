# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## How fast the sheep and townie run.
@export var speed: float = 180

## How long the sheep's head start is.
@export var head_start: float = 1.5

@onready var sheep_path_walk_behavior: PathWalkBehavior = %SheepPathWalkBehavior
@onready var townie_path_walk_behavior: PathWalkBehavior = %TowniePathWalkBehavior


func _ready() -> void:
	# TODO: Give sheep a walk animation
	sheep_path_walk_behavior.speeds.walk_speed = speed

	# Give the sheep a head start!
	await get_tree().create_timer(head_start).timeout

	townie_path_walk_behavior.speeds.walk_speed = speed
