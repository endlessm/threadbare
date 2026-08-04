# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var num_of_entries: int

var num_of_matches: int = 0

signal solved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_matched():
	num_of_matches += 1
	if num_of_matches == num_of_entries:
		solved.emit()
		
func _on_exit(match: bool):
	if (match):
		num_of_matches -= 1
