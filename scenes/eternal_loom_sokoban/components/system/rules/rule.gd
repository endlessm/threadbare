# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@icon("uid://bkdrk0uddqos5")
class_name Rule
extends Node
## A match & replace pattern used in a Sokoban puzzle.
##
## A rule has a match pattern and a replace pattern.
## The match pattern will try and be applied against
## every tile in the board, and if matching will
## replace the pieces with the replace pattern.

var match_pattern: Pattern
var replace_pattern: Pattern


# Virtual function, when called should update match and replace patterns
func setup() -> void:
	pass


# Will apply the rule if possible, and return true/false if success/fail
func apply(board: Board2D, rule_engine: RuleEngine) -> bool:
	setup()

	if not is_valid():
		return false

	var is_applied := false
	var difference_pattern := match_pattern.get_difference(replace_pattern)

	for match_position in match_pattern.get_match_positions(board, rule_engine):
		if match_pattern.match(board, rule_engine, match_position):
			difference_pattern.replace(board, rule_engine, match_position)
			is_applied = true

	for child in get_children():
		if child is Rule:
			is_applied = child.apply(board, rule_engine) or is_applied

	return is_applied


func is_valid() -> bool:
	if not (match_pattern and replace_pattern):
		return false
	return match_pattern.is_valid_pair(replace_pattern)


func _to_string() -> String:
	return "%s -> %s" % [match_pattern.to_string(), replace_pattern.to_string()]
