# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SequencePuzzleStep
extends Node2D

## The sequence of objects the player must interact with to solve this step of the puzzle.
@export var sequence: Array[MusicalRock]:
	set(new_value):
		sequence = new_value
		update_configuration_warnings()

## An optional sign, showing a hint for this step and whether it has been solved.
@export var hint_sign: BonfireSign:
	set(new_value):
		hint_sign = new_value
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if sequence.is_empty():
		warnings.append("Sequence is empty")

	if sequence.find(null) != -1:
		warnings.append("Sequence contains unset elements")

	if not hint_sign:
		warnings.append("Hint Sign not set")

	return warnings
