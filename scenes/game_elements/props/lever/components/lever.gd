# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

signal toggled(is_on: bool)
signal initialized(is_on: bool)

# Note: Changing the value of "is_on" won't emit a signal. To do that, use "toggle"
@export var is_on: bool = false:
	set(new_val):
		is_on = new_val
		update_appearance()

#Toggles can be connected via targets (simple) or via signal (usign the toggled signal)
@export var targets: Array[Toggleable]


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_connect_targets()

	# To ensure both the switch and the targets are ready, we do a "call_deferred"
	initialize_toggle_state.call_deferred()


func _connect_targets() -> void:
	for target: Toggleable in targets:
		initialized.connect(target.initialize_with_value)
		toggled.connect(target.initialize_with_value)


func initialize_toggle_state() -> void:
	initialized.emit(is_on)


func update_appearance() -> void:
	%LeverSprite.frame = 1 if is_on else 0


func _on_interact_area_interaction_started(_from_right: bool) -> void:
	toggle()


func toggle(new_val: bool = not is_on, emit: bool = true) -> void:
	is_on = new_val
	if emit:
		toggled.emit(is_on)
