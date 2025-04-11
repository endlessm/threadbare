# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var directional_input: DirectionalInput
@export var board: Board2D

@export_group("RuleSet")
@export var player_groups: PieceGroups
@export var rules: Array[SokobanRule]

@export_group("Debugging")
@export var show_output: bool = false


func _ready() -> void:
	directional_input.input = _directional_input


func _directional_input(direction_2d: Vector2i) -> bool:
	_take_turn(direction_2d)
	return true


func _take_turn(direction_2d: Vector2i) -> void:
	var move_attempts: Array[MoveAttempt] = []

	# collect all move attempts from player pieces
	for player in board.get_pieces(player_groups):
		move_attempts.append(_make_move_attempt(player, direction_2d))

	if show_output:
		print(move_attempts)

	# run rules here
	for rule in rules:
		for piece in board.get_pieces():
			_attempt_rule_on_piece(rule, piece, move_attempts)

	# do movement here
	var total_checked_attempts: Array[MoveAttempt] = []

	# disable moving pieces to make it easier to get pieces
	for attempt in move_attempts:
		attempt.piece.active = false

	for attempt in move_attempts:
		if attempt in total_checked_attempts:
			continue

		var checked_attempts: Array[MoveAttempt] = []
		var result := attempt.can_move(board, move_attempts, checked_attempts)

		for checked in checked_attempts:
			if result:
				checked.apply()

		total_checked_attempts.append_array(checked_attempts)

	for attempt in move_attempts:
		attempt.piece.active = true

	# run late rules here

	# commands are run here


func _attempt_rule_on_piece(
	rule: SokobanRule, piece: Piece2D, move_attempts: Array[MoveAttempt]
) -> void:
	if not rule.match_pattern:
		return
	if rule.match_pattern.size() == 0:
		return

	# early check
	if not _is_fragment_matching(rule.match_pattern[0], piece, move_attempts):
		return

	var pieces: Array[Piece2D] = [piece]

	# check for the rest of pattern in rule direction if any fragment misses, fail entire check
	var direction_vector := rule.get_vector()
	for i in range(1, rule.match_pattern.size()):
		var fragment := rule.match_pattern[i]

		var next_pieces := board.get_pieces_at(piece.grid_position + direction_vector * i)

		var result := false
		for next in next_pieces:
			if _is_fragment_matching(fragment, next, move_attempts):
				result = true
				pieces.append(next)
				break
		if result == false:
			return

	# rule matches! apply the rule now
	for i in rule.match_pattern.size():
		var fragment := rule.replace_pattern[i]

		if i < pieces.size():
			_apply_fragment(fragment, pieces[i], move_attempts)


func _apply_fragment(
	fragment: RuleFragment, piece: Piece2D, move_attempts: Array[MoveAttempt]
) -> void:
	match fragment.move_context:
		RuleFragment.MOVE.ANY:
			return
		RuleFragment.MOVE.STILL:
			for attempt in move_attempts:
				if attempt.piece == piece:
					move_attempts.erase(attempt)
					break
		_:
			for attempt in move_attempts:
				if attempt.piece == piece:
					move_attempts.erase(attempt)
					break

			move_attempts.append(_make_move_attempt(piece, fragment.get_vector()))


func _is_fragment_matching(
	fragment: RuleFragment, piece: Piece2D, move_attempts: Array[MoveAttempt]
) -> bool:
	if not piece.groups.has_group(fragment.group):
		return false

	if fragment.move_context != RuleFragment.MOVE.ANY:
		for attempt in move_attempts:
			if attempt.piece == piece:
				return fragment.is_matching_movement(
					attempt.new_grid_position - attempt.old_grid_position
				)

	return true


func _make_move_attempt(piece: Piece2D, movement: Vector2i) -> MoveAttempt:
	return MoveAttempt.new(piece, piece.grid_position, piece.grid_position + movement)


class MoveAttempt:
	var piece: Piece2D
	var old_grid_position: Vector2i
	var new_grid_position: Vector2i

	func _init(
		i_piece: Piece2D, i_old_grid_position: Vector2i, i_new_grid_position: Vector2i
	) -> void:
		piece = i_piece
		old_grid_position = i_old_grid_position
		new_grid_position = i_new_grid_position

	func can_move(
		board: Board2D, other_attempts: Array[MoveAttempt], checked_attempts: Array[MoveAttempt]
	) -> bool:
		# check for infinite loop
		if self in checked_attempts:
			return false

		checked_attempts.append(self)

		# check if colliding with non-moving tiles
		if board.get_pieces_at(new_grid_position, null, piece.layer).size() != 0:
			return false

		# check if colliding with moving tiles
		for other in other_attempts:
			# make sure you don't check yourself
			if self == other:
				continue

			# if matching new positions, check if the other attempt can move recursively
			if new_grid_position == other.old_grid_position:
				return other.can_move(board, other_attempts, checked_attempts)

		return true

	func revert() -> void:
		if piece:
			piece.grid_position = old_grid_position

	func apply() -> void:
		if piece:
			piece.grid_position = new_grid_position

	func _to_string() -> String:
		return "Piece %s: %s -> %s" % [piece.name, old_grid_position, new_grid_position]
