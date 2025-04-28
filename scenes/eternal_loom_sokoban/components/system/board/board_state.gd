# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BoardState
extends Resource
## A snapshot of PieceStates.
##
## Represents any changed pieces between steps.
## Used for undo and reset features.

var piece_states: Array[PieceState]


func add_piece_state(piece_state: PieceState) -> void:
	piece_states.append(piece_state)


func apply() -> void:
	for piece_state in piece_states:
		piece_state.apply()


func is_empty() -> bool:
	return piece_states.size() == 0


func _to_string() -> String:
	var state_strs: PackedStringArray
	for piece_state in piece_states:
		state_strs.append(piece_state.to_string())
	return "[%s]" % ", ".join(state_strs)
