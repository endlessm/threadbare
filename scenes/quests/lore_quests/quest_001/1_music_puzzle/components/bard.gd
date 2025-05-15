# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var puzzle: SequencePuzzle

var first_conversation: bool = true


func advance_hint_level() -> void:
	var progress := puzzle.get_progress()
	puzzle.hint_levels[progress] = puzzle.hint_levels.get(progress, 0) + 1


func get_limited_hint_level() -> int:
	var progress = puzzle.get_progress()
	var hint_level = puzzle.hint_levels.get(progress, 0)
	var max_hint_level = 2
	return hint_level % (max_hint_level + 1)
