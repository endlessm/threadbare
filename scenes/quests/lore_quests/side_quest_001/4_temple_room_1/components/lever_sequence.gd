# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var num_of_entries: int = 3

var _objects: Array[ToggableLight]
var _sequence: Dictionary[int, int]
var current_step: int = 0
var done: bool = false

signal solved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_find_objects()

func _find_objects() -> void:
	_objects.clear()
	var num = 0

	for o: Node in get_tree().get_nodes_in_group("lights"):
		if o is ToggableLight:
			var object := o as ToggableLight
			_objects.append(object)
			object.light_enabled.connect(_on_enabled)
			object.light_disabled.connect(_on_disabled)
			object.order = num
			_sequence[num] = -1
			num += 1


func _on_enabled(num: int):
	_sequence[num] = current_step
	current_step += 1
	if current_step >= num_of_entries:
		check()


func _on_disabled(num: int):
	_sequence[num] = -1
	current_step -= 1


func check():
	var correct: bool = true
	for light in _sequence:
		if light != _sequence[light]:
			correct = false
	
	if correct:
		done = true
		solved.emit()
