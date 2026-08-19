# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal solved

@export var num_of_entries: int

var num_of_matches: int = 0


## When the statue's symbol matches the object's symbol, increase the counter.
## If all pressure plates have matching statues on them, emit a signal.
func _on_matched() -> void:
	num_of_matches += 1
	if num_of_matches == num_of_entries:
		solved.emit()


## If a statue is pushed off a pressure plate, decrease the counter.
func _on_exit(match: bool) -> void:
	if match:
		num_of_matches -= 1
