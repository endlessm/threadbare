# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SokobanRule
extends Resource

enum CONTEXT {
	NONE,
	LATE,
}

enum DIRECTION {
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

const DIRECTION_VECTORS := {
	DIRECTION.UP: Vector2i.UP,
	DIRECTION.RIGHT: Vector2i.RIGHT,
	DIRECTION.DOWN: Vector2i.DOWN,
	DIRECTION.LEFT: Vector2i.LEFT,
}

@export var direction: DIRECTION
@export var contexts: Array[CONTEXT]
@export var match_pattern: Array[RuleFragment]
@export var replace_pattern: Array[RuleFragment]


func get_vector() -> Vector2i:
	return DIRECTION_VECTORS[direction]
