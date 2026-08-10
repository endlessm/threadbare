# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Toggleable

@export var play_victory_fanfare_on_open: bool = false
@export var opened: bool = false:
	set(new_val):
		opened = new_val
		update_opened_state()
@onready var ring_sound: AudioStreamPlayer = $RingSound
@onready var door_sound: AudioStreamPlayer2D = $DoorSound


func open() -> void:
	if play_victory_fanfare_on_open:
		ring_sound.play()
	door_sound.play()
	set_toggled(true)


func close() -> void:
	set_toggled(false)


func set_toggled(value: bool) -> void:
	opened = value


func update_opened_state() -> void:
	%DoorClosed.visible = !opened
	%DoorOpened.visible = opened

	%ColliderWhenClosed.set_collision_layer_value(Enums.CollisionLayers.WALLS, not opened)
	%ColliderWhenClosed.set_collision_mask_value(Enums.CollisionLayers.PLAYERS, not opened)
