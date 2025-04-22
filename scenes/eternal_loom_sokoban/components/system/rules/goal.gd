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

# Virtual function, when called should return if goal is matched or failed
@warning_ignore("unused_parameter")


func is_completed(board: Board2D, rule_engine: RuleEngine) -> bool:
	var result := true

	for child in get_children():
		if child is Goal:
			result = child.is_completed(board, rule_engine) and result

	return result
