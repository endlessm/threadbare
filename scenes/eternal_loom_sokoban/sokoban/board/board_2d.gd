# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
@icon("res://scenes/sokoban/icons/board_2d.svg")
class_name Board2D
extends Node2D

signal piece_added(piece: Piece2D)
signal piece_removed(piece: Piece2D)

@export var tile_size: Vector2 = Vector2(100, 100)

var _pieces: Array[Piece2D] = []
var _cells_by_position: Dictionary[Vector2i, Cell2D] = {}
var _cells_by_piece: Dictionary[Piece2D, Cell2D] = {}


func position_to_grid_position(world_position: Vector2) -> Vector2i:
	return Vector2i(world_position / tile_size)


func grid_position_to_position(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * tile_size


#region Queries
func is_empty(grid_position: Vector2i, groups: PieceGroups = null, layer: int = -1) -> bool:
	_update_cells()

	# No cell here yet
	if not _cells_by_position.has(grid_position):
		return true
	var cell := _cells_by_position[grid_position]
	# Nothing in this cell
	if cell.is_empty():
		return true

	# No group filter and there is a non-empty cell
	if not PieceGroups.is_valid(groups):
		return false

	for piece in cell.pieces:
		if piece.is_in_groups(groups) and piece.is_in_layer(layer):
			return false

	return true


func get_piece_at(grid_position: Vector2i, groups: PieceGroups = null, layer: int = -1) -> Piece2D:
	return get_pieces_at(grid_position, groups, layer)[0]


func get_pieces_at(
	grid_position: Vector2i, groups: PieceGroups = null, layer: int = -1
) -> Array[Piece2D]:
	_update_cells()

	# No cell here yet
	if not _cells_by_position.has(grid_position):
		return []
	var cell := _cells_by_position[grid_position]
	# Nothing in this cell
	if cell.is_empty():
		return []
	# No group filter, return all pieces in cell
	if not PieceGroups.is_valid(groups):
		return cell.pieces

	var result: Array[Piece2D] = []
	# Build an array of all pieces that match the group filter
	for piece in _cells_by_position[grid_position].pieces:
		if piece.is_in_groups(groups) and piece.is_in_layer(layer):
			result.append(piece)

	return result


## Get the first piece registered (optionally filtered by group, optionally including inactive)
func get_piece(
	groups: PieceGroups = null, layer: int = -1, include_inactive: bool = false
) -> Piece2D:
	for piece in _pieces:
		# Piece matches filter
		if _piece_filter(piece, groups, layer, include_inactive):
			return piece
	# Found nothing
	return null


## Get all pieces (optionally filtered by group, optionally including inactive)
func get_pieces(
	groups: PieceGroups = null, layer: int = -1, include_inactive: bool = false
) -> Array[Piece2D]:
	var filtered_by_group: bool = PieceGroups.is_valid(groups)
	# We just want all pieces
	if not filtered_by_group:
		return _pieces
	# Filter pieces by what matches
	return _pieces.filter(_piece_filter.bind(groups, layer, include_inactive))


## Count all pieces (optionally filtered by group, optionally including inactive)
func count_pieces(
	groups: PieceGroups = null, layer: int = -1, include_inactive: bool = false
) -> int:
	var filtered_by_group: bool = PieceGroups.is_valid(groups)
	# We just want all pieces
	if not filtered_by_group:
		return _pieces.size()
	# Filter pieces by what matches
	var piece_count := 0
	for piece in _pieces:
		if _piece_filter(piece, groups, layer, include_inactive):
			piece_count += 1
	return piece_count


#endregion


#region Internal
func _register_piece(piece: Piece2D) -> void:
	_pieces.append(piece)
	_update_piece_cell(piece)
	piece_added.emit(piece)


func _deregister_piece(piece: Piece2D) -> void:
	_pieces.erase(piece)
	# Remove piece from cell if it was active
	if _cells_by_piece.has(piece):
		var cell := _cells_by_piece[piece]
		cell.pieces.erase(piece)
		_cells_by_piece.erase(piece)
	piece_removed.emit(piece)


func _update_cells() -> void:
	for piece in _pieces:
		_update_piece_cell(piece)


func _update_piece_cell(piece: Piece2D) -> void:
	# Update which cell the piece sits in
	var previous_cell := _cells_by_piece.get(piece) as Cell2D
	var new_cell := _get_or_create_cell(piece.grid_position) if piece.active else null
	# Piece didn't change cells
	if previous_cell == new_cell:
		return
	# Remove from old cell
	if previous_cell:
		previous_cell.pieces.erase(piece)
		_cells_by_piece.erase(piece)
	# Add to new cell
	if new_cell:
		new_cell.pieces.append(piece)
		_cells_by_piece[piece] = new_cell


func _get_or_create_cell(grid_position: Vector2i) -> Cell2D:
	if not _cells_by_position.has(grid_position):
		_cells_by_position[grid_position] = Cell2D.new(grid_position)
	return _cells_by_position[grid_position]


func _piece_filter(piece: Piece2D, groups: PieceGroups, layer: int, include_inactive: bool) -> bool:
	# We don't want inactive pieces and piece is inactive
	if not include_inactive and not piece.active:
		return false
	# Piece doesn't match the group filter
	if groups and not groups.is_empty():
		if not piece.is_in_groups(groups):
			return false
	# Piece doesn't match layer
	if not piece.is_in_layer(layer):
		return false
	# Piece satisfies filter
	return true


#endregion


class Cell2D:
	var grid_position: Vector2i
	var pieces: Array[Piece2D] = []

	func _init(_grid_position: Vector2i) -> void:
		grid_position = _grid_position

	func is_empty() -> bool:
		return pieces.size() == 0
