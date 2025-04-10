# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name RuleFragment
extends Resource
## A group identifier and a movement context
##
## RuleFragments are used to compare against a piece in a SokobanRule.
## They hold a single group identifier and a context for what direction
## (if any) it is moving.

enum MOVE {
	ANY,
	STILL,
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

const MOVE_DIRECTIONS := {
	Vector2i.ZERO: MOVE.STILL,
	Vector2i.UP: MOVE.UP,
	Vector2i.RIGHT: MOVE.RIGHT,
	Vector2i.DOWN: MOVE.DOWN,
	Vector2i.LEFT: MOVE.LEFT,
}

const DIRECTION_TO_VECTORS := {
	MOVE.UP: Vector2i.UP,
	MOVE.RIGHT: Vector2i.RIGHT,
	MOVE.DOWN: Vector2i.DOWN,
	MOVE.LEFT: Vector2i.LEFT,
}

@export var move_context: MOVE
@export var group: StringName


func get_groups() -> PieceGroups:
	return PieceGroups.from_group(group)


func is_matching_movement(movement: Vector2i) -> bool:
	return MOVE_DIRECTIONS[movement] == move_context or move_context == MOVE.ANY


func get_vector() -> Vector2i:
	if DIRECTION_TO_VECTORS.has(move_context):
		return DIRECTION_TO_VECTORS[move_context]
	return Vector2.ZERO
