# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name GoalAllOn
extends Goal
## A Goal Type that checks if every target has a key on top of it.

@export var key: StringName
@export var target: StringName


func _is_self_completed(board: Board2D, rule_engine: RuleEngine) -> bool:
	var key_query := Board2D.Query.new().add_id_or_tag(key, rule_engine)
	var target_query := Board2D.Query.new().add_id_or_tag(target, rule_engine)

	for board_target in board.get_pieces(target_query):
		if board.is_empty(board_target.grid_position, key_query):
			return false

	return super(board, rule_engine)
