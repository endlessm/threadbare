# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

## Emitted when the scene starts, indicating the initial state of this unlocker.
signal initialized(satisfied: bool)

## Emitted when the lever state changes.
signal toggled(is_on: bool)

const ON_SIDE := Enums.LookAtSide.RIGHT

const FRAME_FOR_SIDE: Dictionary[Enums.LookAtSide, int] = {
	Enums.LookAtSide.LEFT: 0,
	Enums.LookAtSide.RIGHT: 1,
}

# Toggles can be connected via targets (simple) or via signal (using the toggled signal)
@export var targets: Array[Toggleable]

var lever_side: Enums.LookAtSide = Enums.LookAtSide.LEFT:
	set = set_lever_side

@onready var lever_sprite: Sprite2D = %LeverSprite
@onready var shaker: Shaker = %Shaker


func update_appearance() -> void:
	lever_sprite.frame = FRAME_FOR_SIDE[lever_side]


func set_lever_side(new_side: Enums.LookAtSide) -> void:
	lever_side = new_side
	update_appearance()
	toggled.emit(lever_side == ON_SIDE)


func _ready() -> void:
	set_lever_side(lever_side)
	_connect_targets()

	# To ensure the targets are ready, we do a "call_deferred"
	_initialize_toggle_state.call_deferred()


func _initialize_toggle_state() -> void:
	initialized.emit(lever_side == ON_SIDE)


func _connect_targets() -> void:
	for target: Toggleable in targets:
		initialized.connect(target.initialize_with_value)
		toggled.connect(target.set_toggled)


func got_repelled(direction: Vector2) -> void:
	var sign_x := signf(direction.x)
	var new_side: Enums.LookAtSide
	if sign_x == 1:
		new_side = Enums.LookAtSide.RIGHT
	elif sign_x == -1:
		new_side = Enums.LookAtSide.LEFT
	if new_side == lever_side:
		shaker.shake()
	else:
		lever_side = new_side
