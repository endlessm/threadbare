# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name RulePush
extends Rule
## A Rule Type that will allow pushing a piece in a given direction.
##
## The rule checks if a pusher piece is moving into a pushee piece.
## If so, set the movement of pushee to be in the same direction.

enum DIRECTION {
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

@export var pusher: StringName
@export var pushee: StringName
@export var direction: DIRECTION


func setup() -> void:
	const DIRECTION_TO_VECTOR: Dictionary[DIRECTION, Vector2i] = {
		DIRECTION.UP: Vector2i(0, -1),
		DIRECTION.RIGHT: Vector2i(1, 0),
		DIRECTION.DOWN: Vector2i(0, 1),
		DIRECTION.LEFT: Vector2i(-1, 0),
	}

	const DIRECTION_TO_PIECE_DIRECTION: Dictionary[DIRECTION, Piece2D.DIRECTION] = {
		DIRECTION.UP: Piece2D.DIRECTION.UP,
		DIRECTION.RIGHT: Piece2D.DIRECTION.RIGHT,
		DIRECTION.DOWN: Piece2D.DIRECTION.DOWN,
		DIRECTION.LEFT: Piece2D.DIRECTION.LEFT,
	}

	match_pattern = (
		Pattern
		. new()
		. add_cell(
			Pattern.Cell.new().add_pattern_piece(
				Pattern.PatternPiece.new(pusher, DIRECTION_TO_PIECE_DIRECTION[direction])
			)
		)
		. add_cell(
			Pattern.Cell.new(DIRECTION_TO_VECTOR[direction]).add_pattern_piece(
				Pattern.PatternPiece.new(pushee, Piece2D.DIRECTION.NONE)
			)
		)
	)

	replace_pattern = (
		Pattern
		. new()
		. add_cell(
			Pattern.Cell.new().add_pattern_piece(
				Pattern.PatternPiece.new(pusher, DIRECTION_TO_PIECE_DIRECTION[direction])
			)
		)
		. add_cell(
			Pattern.Cell.new(DIRECTION_TO_VECTOR[direction]).add_pattern_piece(
				Pattern.PatternPiece.new(pushee, DIRECTION_TO_PIECE_DIRECTION[direction])
			)
		)
	)
