# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BarrelUnlockSequence
extends Node

@export var barrels: Array[FillingBarrel]
@export var auto_start: bool = true

var current_target_index: int = 0


func _ready() -> void:
	if auto_start:
		call_deferred("start_sequence")


func start_sequence() -> void:
	randomize()

	if barrels.is_empty():
		push_warning("BarrelUnlockSequence: No barrels assigned.")
		return

	barrels.shuffle()

	for barrel in barrels:
		if not barrel.completed.is_connected(_on_barrel_completed):
			barrel.completed.connect(_on_barrel_completed)

		# Initial state: all locked
		barrel.set_locked_state(true)

	unlock_next_barrel()


func unlock_next_barrel() -> void:
	if current_target_index < barrels.size():
		var target: FillingBarrel = barrels[current_target_index]

		if is_instance_valid(target):
			target.set_locked_state(false)


func _on_barrel_completed() -> void:
	current_target_index += 1
	unlock_next_barrel()
