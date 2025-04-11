# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
@icon("res://scenes/sokoban/icons/piece_2d.svg")
class_name Piece2D
extends Node2D

@export var groups: PieceGroups:
	get = _get_groups,
	set = _set_groups
@export var layer: int

var active: bool = true
## `global_position`, rounded to snap to the grid
var grid_position: Vector2i:
	get = _get_grid_position,
	set = _set_grid_position
var _board: Board2D:
	set = _set_board


func _enter_tree() -> void:
	_board = _find_ancestor_board()


func _exit_tree() -> void:
	_board = null


func _get_groups() -> PieceGroups:
	return groups


func _set_groups(value: PieceGroups) -> void:
	groups = value


func is_in_groups(target_groups: PieceGroups) -> bool:
	return groups.has_groups(target_groups)


func is_in_layer(target_layer: int) -> bool:
	return layer == target_layer or target_layer == -1


func _get_grid_position() -> Vector2i:
	if _board:
		return _board.position_to_grid_position(global_position)

	push_warning("Piece \"%s\" is missing a board reference and couldn't get it's position!" % name)
	return Vector2i(global_position)


func _set_grid_position(value: Vector2i) -> void:
	if _board:
		global_position = _board.grid_position_to_position(value)
	else:
		push_warning(
			"Piece \"%s\" is missing a board reference and couldn't set it's position!" % name
		)


func _set_board(value: Board2D) -> void:
	if _board:
		_board._deregister_piece(self)
	_board = value
	if value:
		value._register_piece(self)


func _find_ancestor_board() -> Board2D:
	const MAX_SEARCH_DEPTH := 8
	var search_node: Node = self
	# Search our parent and parent of parent, etc
	for i in range(MAX_SEARCH_DEPTH):
		var search_parent := search_node.get_parent()
		# Reached the root without finding it
		if not search_parent:
			return null
		# Found the Board
		if search_parent is Board2D:
			return search_parent as Board2D
		# Update which node we're looking at for next iteration
		search_node = search_parent
	# Reached max search depth
	return null
