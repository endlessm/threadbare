# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal solved

@export var num_of_entries: int = 3

var current_step: int = 0
var done: bool = false

var _objects: Array[ToggableLight]
var _sequence: Dictionary[int, int]


## At the start, calls the function that finds all lights in the puzzle.
func _ready() -> void:
	_find_objects()


## Finds all lights in the puzzle.
func _find_objects() -> void:
	_objects.clear()
	var num: int = 0

	for o: Node in get_tree().get_nodes_in_group("lights"):
		if o is ToggableLight:
			var object := o as ToggableLight
			_objects.append(object)
			object.light_enabled.connect(_on_enabled)
			object.light_disabled.connect(_on_disabled)
			object.order = num
			_sequence[num] = -1
			num += 1


## When the lever is turned on, it saves in what order its corresponding light was toggled.
## If all lights are toggled, it calls the function that checks if the lights were toggled in
## the right order.
func _on_enabled(num: int) -> void:
	_sequence[num] = current_step
	current_step += 1
	if current_step >= num_of_entries:
		check()


## When the lever is disabled, its placement in the saved order is reset.
func _on_disabled(num: int) -> void:
	_sequence[num] = -1
	current_step -= 1


## Check whether all lights were toggled in the correct order based on their saved order.
func check() -> void:
	var correct: bool = true
	for light in _sequence:
		if light != _sequence[light]:
			correct = false

	if correct:
		done = true
		solved.emit()
