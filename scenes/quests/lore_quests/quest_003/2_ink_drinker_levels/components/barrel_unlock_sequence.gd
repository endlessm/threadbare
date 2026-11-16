# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BarrelUnlockSequence
extends Node

@export var barrels: Array[FillingBarrel]
@export var auto_start: bool = true
@export var randomize_barrel_order: bool = false

var current_target_index: int = 0


func _ready() -> void:
	if auto_start:
		start_sequence.call_deferred()


func start_sequence() -> void:
	if barrels.is_empty():
		push_warning("BarrelUnlockSequence: No barrels assigned.")
		return

	if randomize_barrel_order:
		barrels.shuffle()

	for barrel in barrels:
		if not barrel.completed.is_connected(_on_barrel_completed):
			barrel.completed.connect(_on_barrel_completed)

		# Initial state: all locked
		barrel.is_locked = true

	unlock_next_barrel()


func unlock_next_barrel() -> void:
	if current_target_index < barrels.size():
		var target: FillingBarrel = barrels[current_target_index]
		target.is_locked = false


func _on_barrel_completed() -> void:
	current_target_index += 1
	unlock_next_barrel()
