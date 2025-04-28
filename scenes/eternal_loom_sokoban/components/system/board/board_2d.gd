# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
@icon("uid://bwkomj8lfylk2")
class_name Board2D
extends Node2D
## A queriable holder of Piece2D's.
##
## Watches for pieces that enter or exit as a child (or grandchild).
## Can be queried to get specific piece types.
## Based on a specific "grid size".

signal piece_added(piece: Piece2D)
signal piece_removed(piece: Piece2D)

@export var tile_size: Vector2 = Vector2(64, 64)
@export var offset_tiles: bool = true

var _pieces: Array[Piece2D] = []
var _cells_by_position: Dictionary[Vector2i, Cell2D] = {}
var _cells_by_piece: Dictionary[Piece2D, Cell2D] = {}


func position_to_grid_position(world_position: Vector2) -> Vector2i:
	return Vector2i(
		(world_position - (tile_size * 0.5 if offset_tiles else Vector2.ZERO)) / tile_size
	)


func grid_position_to_position(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * tile_size + (tile_size * 0.5 if offset_tiles else Vector2.ZERO)


#region Queries
func is_empty(grid_position: Vector2i, query: Query = null) -> bool:
	_update_cells()

	# No cell here yet
	if not _cells_by_position.has(grid_position):
		return true
	var cell := _cells_by_position[grid_position]
	# Nothing in this cell
	if cell.is_empty():
		return true

	# No group filter and there is a non-empty cell
	if query == null:
		return false

	for piece in cell.pieces:
		if query.matches(piece):
			return false

	return true


func get_piece_at(grid_position: Vector2i, query: Query = null) -> Piece2D:
	var result := get_pieces_at(grid_position, query)
	if result.size() == 0:
		return null
	return result[0]


func get_pieces_at(grid_position: Vector2i, query: Query = null) -> Array[Piece2D]:
	_update_cells()

	# No cell here yet
	if not _cells_by_position.has(grid_position):
		return []
	var cell := _cells_by_position[grid_position]
	# Nothing in this cell
	if cell.is_empty():
		return []
	# No group filter, return all pieces in cell
	if query == null:
		return cell.pieces

	var result: Array[Piece2D] = []
	# Build an array of all pieces that match the group filter
	for piece in _cells_by_position[grid_position].pieces:
		if query.matches(piece):
			result.append(piece)

	return result


## Get the first piece registered (optionally filtered by group, optionally including inactive)
func get_piece(query: Query = null) -> Piece2D:
	for piece in _pieces:
		# Piece matches filter
		if query.matches(piece):
			return piece
	# Found nothing
	return null


## Get all pieces (optionally filtered by group, optionally including inactive)
func get_pieces(query: Query = null) -> Array[Piece2D]:
	# We just want all pieces
	if query == null:
		return _pieces
	# Filter pieces by what matches
	return _pieces.filter(query.matches)


## Count all pieces (optionally filtered by group, optionally including inactive)
func count_pieces(query: Query = null) -> int:
	# We just want all pieces
	if query == null:
		return _pieces.size()
	# Filter pieces by what matches
	var piece_count := 0
	for piece in _pieces:
		if query.matches(piece):
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


#endregion


class Cell2D:
	var grid_position: Vector2i
	var pieces: Array[Piece2D]

	func _init(_grid_position: Vector2i) -> void:
		grid_position = _grid_position

	func is_empty() -> bool:
		return pieces.size() == 0


class Query:
	var id: StringName = ""
	var tags: Array[StringName] = []
	var layer: int = -1
	var direction: Piece2D.DIRECTION = Piece2D.DIRECTION.ANY

	var include_inactive: bool = false
	var is_exclusive: bool = false
	var is_tags_exhaustive: bool = false

	var next_query: Query = null

	func add_piece(piece: Piece2D) -> Query:
		id = piece.id
		tags = piece.tags
		layer = piece.layer
		return self

	func add_pattern_piece(piece: Pattern.PatternPiece, rule_engine: RuleEngine) -> Query:
		add_id_or_tag(piece.id_or_tag, rule_engine)
		direction = piece.direction

		return self

	func add_id(value: StringName) -> Query:
		id = value
		return self

	func add_tag(value: StringName) -> Query:
		tags.append(value)
		return self

	func add_tags(values: Array[StringName]) -> Query:
		tags.append_array(values)
		return self

	func add_id_or_tag(value: StringName, rule_engine: RuleEngine) -> Query:
		if value in rule_engine.tags_legend:
			tags.append(value)
		else:
			id = value
		return self

	func add_layer(value: int) -> Query:
		layer = value
		#prints("VALUE", value, "SELF:", self.layer)
		return self

	func add_direction(value: Piece2D.DIRECTION) -> Query:
		direction = value
		return self

	func set_include_inactive(value: bool) -> Query:
		include_inactive = value
		return self

	func set_is_exclusive(value: bool) -> Query:
		is_exclusive = value
		return self

	func set_is_tags_exhaustive(value: bool) -> Query:
		is_tags_exhaustive = value
		return self

	## Used to chain additional queries to the current Query
	func add_next_query() -> Query:
		next_query = Query.new()
		return next_query

	func matches(piece: Piece2D) -> bool:
		var found_fault := false

		# We don't want inactive pieces and piece is inactive
		if not include_inactive and not piece.active:
			if not found_fault:
				found_fault = true
			# return is_exclusive
		# Piece doesn't match the id
		if id != "":
			if id != piece.id:
				if not found_fault:
					found_fault = true
				# return is_exclusive
		# Piece doesn't match the tags
		if is_tags_exhaustive:
			for tag in tags:
				if not tag in piece.tags:
					if not found_fault:
						found_fault = true
					# return is_exclusive
		else:
			if tags.size() > 0:
				var is_match := false
				for tag in tags:
					if tag in piece.tags:
						is_match = true
						break
				if not is_match:
					if not found_fault:
						found_fault = true
					# return is_exclusive
		# Piece doesn't match layers
		#prints(piece.layer, "|", layer)
		if not piece.on_same_layer(layer):
			if not found_fault:
				found_fault = true
			# return is_exclusive
		# Piece doesn't match directions
		if not piece.same_direction(direction):
			if not found_fault:
				found_fault = true
			# return is_exclusive
		# Piece satisfies filter

		# Recursively check next queries if they also match
		if next_query:
			if not next_query.matches(piece):
				if not found_fault:
					found_fault = true
				# return is_exclusive

		if found_fault:
			return is_exclusive
		return not is_exclusive
