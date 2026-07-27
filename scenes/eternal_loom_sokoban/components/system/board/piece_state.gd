# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PieceState
extends Resource
## A snapshot of a Piece2D.
##
## Represents a piece at a given position.

var piece: Piece2D
var grid_position: Vector2i


static func from_piece(new_piece: Piece2D) -> PieceState:
	return PieceState.new(new_piece, new_piece.grid_position)


func _init(i_piece: Piece2D, i_grid_position: Vector2i) -> void:
	piece = i_piece
	grid_position = i_grid_position


func apply() -> void:
	if piece:
		piece.grid_position = grid_position


func _to_string() -> String:
	return "%s %s" % [grid_position, piece.id]
