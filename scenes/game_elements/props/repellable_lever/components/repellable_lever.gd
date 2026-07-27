# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

## Emitted when the scene starts, indicating the initial state of this lever.
signal initialized(satisfied: bool)

## Emitted when the lever state changes.
signal toggled(is_on: bool)

# Note: Changing the value of "is_on" won't emit a signal. To do that, use "toggle"
@export var is_on: bool = false:
	set(new_val):
		is_on = new_val
		update_appearance()

# Toggles can be connected via targets (simple) or via signal (using the toggled signal)
@export var targets: Array[Toggleable]

@onready var lever_sprite: Sprite2D = %LeverSprite
@onready var shaker: Shaker = %Shaker


func update_appearance() -> void:
	if not is_node_ready():
		return
	lever_sprite.frame = 1 if is_on else 0


func _ready() -> void:
	_connect_targets()

	# To ensure the targets are ready, we do a "call_deferred"
	_initialize_toggle_state.call_deferred()


func _initialize_toggle_state() -> void:
	initialized.emit(is_on)


func _connect_targets() -> void:
	for target: Toggleable in targets:
		initialized.connect(target.initialize_with_value)
		toggled.connect(target.set_toggled)


func got_repelled(direction: Vector2) -> void:
	var sign_x := signf(direction.x)
	if sign_x == 1 and not is_on:
		toggle()
	elif sign_x == -1 and is_on:
		toggle()
	else:
		shaker.shake()


func toggle(new_val: bool = not is_on) -> void:
	is_on = new_val
	toggled.emit(is_on)
