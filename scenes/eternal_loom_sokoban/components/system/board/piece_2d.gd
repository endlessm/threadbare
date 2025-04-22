# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
@icon("uid://se752qk48n2u")
class_name Piece2D
extends Node2D
## A single tile as part of a Board2D.
##
## Can be added as a child (or grandchild) of a Board2D.
## Can be identified by it's Id or by it's tags by the Board2D.
## Can also hold a direction, and "step" in that direction.

enum DIRECTION {
	ANY,
	NONE,
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

const DIRECTION_TO_KEY: Dictionary[DIRECTION, StringName] = {
	DIRECTION.ANY: "",
	DIRECTION.NONE: "",
	DIRECTION.UP: "^",
	DIRECTION.RIGHT: ">",
	DIRECTION.DOWN: "v",
	DIRECTION.LEFT: "<",
}

## Unique Identifier for this piece. Should not match any other piece.
@export var id: StringName
## Tag Identifiers for this piece. Pieces can share the same tag.
@export var tags: Array[StringName]

var layer: int:
	set(value):
		layer = value
		z_index = layer

var direction: DIRECTION = DIRECTION.NONE

var active: bool = true

var grid_position: Vector2i:
	get = _get_grid_position,
	set = _set_grid_position
var _board: Board2D:
	set = _set_board


func _enter_tree() -> void:
	_board = _find_ancestor_board()


func _exit_tree() -> void:
	_board = null


func on_same_layer(target_layer: int) -> bool:
	return layer == target_layer or layer == -1 or target_layer == -1


func same_direction(target_direction: DIRECTION) -> bool:
	return (
		direction == target_direction
		or direction == DIRECTION.ANY
		or target_direction == DIRECTION.ANY
	)


func get_vector() -> Vector2i:
	const DIRECTION_TO_VECTOR: Dictionary[DIRECTION, Vector2i] = {
		DIRECTION.NONE: Vector2i.ZERO,
		DIRECTION.UP: Vector2i.UP,
		DIRECTION.RIGHT: Vector2i.RIGHT,
		DIRECTION.DOWN: Vector2i.DOWN,
		DIRECTION.LEFT: Vector2i.LEFT,
	}
	if DIRECTION_TO_VECTOR.has(direction):
		return DIRECTION_TO_VECTOR[direction]
	return Vector2.ZERO


func set_vector(vector: Vector2i) -> void:
	const VECTOR_TO_DIRECTION: Dictionary[Vector2i, DIRECTION] = {
		Vector2i.ZERO: DIRECTION.NONE,
		Vector2i.UP: DIRECTION.UP,
		Vector2i.RIGHT: DIRECTION.RIGHT,
		Vector2i.DOWN: DIRECTION.DOWN,
		Vector2i.LEFT: DIRECTION.LEFT,
	}

	if VECTOR_TO_DIRECTION.has(vector):
		direction = VECTOR_TO_DIRECTION[vector]
		return
	direction = DIRECTION.NONE


func get_new_grid_position() -> Vector2i:
	return grid_position + get_vector()


func cancel_movement() -> void:
	direction = DIRECTION.NONE


func apply_movement() -> void:
	grid_position = get_new_grid_position()
	direction = DIRECTION.NONE


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
		layer = 0
	_board = value
	if value:
		value._register_piece(self)
		if get_parent() and get_parent().get_parent() == value:
			layer = get_parent().get_index()


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
