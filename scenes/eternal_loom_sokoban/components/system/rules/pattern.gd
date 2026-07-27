# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Pattern
extends Resource
## A list of cells that can be compared against a Board2D.
##
## A pattern has cells which hold pattern pieces.
## These pattern pieces can be compared against Piece2D
## to check if they match or not.
## Patterns can be added together to get their difference.

var cells: Array[Cell]


func _init(i_cells: Array[Cell] = []) -> void:
	cells = i_cells


func get_difference(other_pattern: Pattern) -> Pattern:
	if not is_valid_pair(other_pattern):
		return null

	var pattern := Pattern.new()

	for i in size():
		var cell := cells[i]
		var other_cell := other_pattern.cells[i]

		var difference := cell.get_difference(other_cell)

		pattern.add_cell(difference)

	return pattern


# this is used to limit the amount each rule needs to search to find a valid match
func get_match_positions(board: Board2D, rule_engine: RuleEngine) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not is_valid():
		return result

	var query := Board2D.Query.new().add_pattern_piece(cells[0].pattern_pieces[0], rule_engine)

	var pieces := board.get_pieces(query)

	for piece in pieces:
		result.append(piece.grid_position)

	return result


## Returns if current pattern matches board given a starting piece
func match(board: Board2D, rule_engine: RuleEngine, grid_position: Vector2i) -> bool:
	for cell in cells:
		if cell:
			for pattern_piece in cell.pattern_pieces:
				var query := Board2D.Query.new().add_pattern_piece(pattern_piece, rule_engine)

				var piece_at := board.get_piece_at(grid_position + cell.relative_position, query)

				if not piece_at:
					return false

	return true


## Adds, removes, or changes pieces to board given a grid position
func replace(board: Board2D, rule_engine: RuleEngine, grid_position: Vector2i) -> void:
	if not is_valid():
		return

	for cell in cells:
		for pattern_piece in cell.pattern_pieces:
			var query := Board2D.Query.new().add_id_or_tag(pattern_piece.id_or_tag, rule_engine)

			var pieces_at := board.get_pieces_at(grid_position + cell.relative_position, query)

			for piece in pieces_at:
				match pattern_piece.state:
					PatternPiece.STATE.ADDED:
						pass
					PatternPiece.STATE.REMOVED:
						pass
					PatternPiece.STATE.NEUTRAL:
						piece.direction = pattern_piece.direction


func add_cell(cell: Cell) -> Pattern:
	cells.append(cell)
	return self


func is_valid() -> bool:
	return cells.size() > 0


## Returns if this pattern and the chosen pattern can be match & replaced with each other.
func is_valid_pair(pattern: Pattern) -> bool:
	if not (pattern and is_valid() and pattern.is_valid() and size() == pattern.size()):
		return false

	for i in size():
		var cell := cells[i]
		var other_cell := pattern.cells[i]

		if cell.relative_position != other_cell.relative_position:
			return false

	return true


func size() -> int:
	return cells.size()


func _to_string() -> String:
	var cell_strs: PackedStringArray
	for cell in cells:
		cell_strs.append(cell.to_string())
	return "[%s]" % " | ".join(cell_strs)


class Cell:
	var relative_position: Vector2i
	var pattern_pieces: Array[PatternPiece]

	func _init(i_relative_position: Vector2i = Vector2i.ZERO) -> void:
		relative_position = i_relative_position

	# only adds unique pieces
	func add_pattern_piece(added_piece: PatternPiece) -> Cell:
		if not added_piece:
			return self

		for piece in pattern_pieces:
			if piece.matches_pattern_piece(added_piece):
				return self
		pattern_pieces.append(added_piece)
		return self

	func size() -> int:
		return pattern_pieces.size()

	func get_difference(other_cell: Cell) -> Cell:
		var cell := Cell.new(relative_position)

		if not other_cell:
			return cell

		# get new pieces in other cell
		for other_piece in other_cell.pattern_pieces:
			if not includes_pattern_piece(other_piece):
				var added_piece := other_piece.duplicate()
				added_piece.state = PatternPiece.STATE.ADDED
				cell.add_pattern_piece(added_piece)

		# get changed/removed pieces in other cell
		for piece in pattern_pieces:
			# changed pieces
			for other_piece in other_cell.pattern_pieces:
				if piece.id_or_tag == other_piece.id_or_tag:
					if not piece.matches_pattern_piece(other_piece):
						cell.add_pattern_piece(other_piece.duplicate())

			# removed pieces
			if not other_cell.includes_pattern_piece(piece):
				var removed_piece := piece.duplicate()
				removed_piece.state = PatternPiece.STATE.REMOVED
				cell.add_pattern_piece(removed_piece)

		return cell

	func includes_pattern_piece(other_piece: PatternPiece) -> bool:
		for pattern_piece in pattern_pieces:
			if pattern_piece.id_or_tag == other_piece.id_or_tag:
				return true
		return false

	func _to_string() -> String:
		var pattern_piece_strs: PackedStringArray
		for pattern_piece in pattern_pieces:
			pattern_piece_strs.append(pattern_piece.to_string())
		return "%s %s" % [relative_position, " ".join(pattern_piece_strs)]


class PatternPiece:
	enum STATE {
		NEUTRAL,
		ADDED,
		REMOVED,
	}

	var id_or_tag: StringName = ""
	var direction: Piece2D.DIRECTION = Piece2D.DIRECTION.ANY
	var state: STATE = STATE.NEUTRAL

	func _init(
		i_id_or_tag: StringName = "", i_direction := Piece2D.DIRECTION.ANY, i_state := STATE.NEUTRAL
	) -> void:
		id_or_tag = i_id_or_tag
		direction = i_direction
		state = i_state

	func matches_pattern_piece(piece: PatternPiece) -> bool:
		if id_or_tag != piece.id_or_tag:
			return false
		if direction != piece.direction:
			return false
		if state != piece.state:
			return false
		return true

	func duplicate() -> PatternPiece:
		return PatternPiece.new(id_or_tag, direction, state)

	func _to_string() -> String:
		var dir_text := Piece2D.DIRECTION_TO_KEY[direction]
		if dir_text != "":
			dir_text += " "
		var state_text: String = {
			STATE.NEUTRAL: "",
			STATE.ADDED: "+",
			STATE.REMOVED: "-",
		}[state]
		return dir_text + state_text + str(id_or_tag)
