# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@icon("uid://chphnvnvabaoh")
class_name Goal
extends Node
## A match pattern used in a Sokoban puzzle.
##
## A Goal will be checked after every turn
## to see if there is a match. If so,
## it will return true to the RuleEngine.


## Returns true if this goal, and all child goals (if any) are matched; false otherwise.
func is_all_completed(board: Board2D, rule_engine: RuleEngine) -> bool:
	if not _is_self_completed(board, rule_engine):
		return false

	for child in get_children():
		if child is Goal:
			if not child.is_all_completed(board, rule_engine):
				return false

	return true


## Returns true if this goal is matched; false otherwise.
## Subclasses should override this method.
func _is_self_completed(_board: Board2D, _rule_engine: RuleEngine) -> bool:
	return true
