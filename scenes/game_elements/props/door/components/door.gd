# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Toggleable

@export var play_victory_fanfare_on_open: bool = false
@export var opened: bool = false:
	set(new_val):
		opened = new_val
		update_opened_state()

@onready var door_open_sound: AudioStreamPlayer2D = %DoorOpenSound
@onready var victory_sound: AudioStreamPlayer = %VictorySound


func open() -> void:
	set_toggled(true)


func close() -> void:
	set_toggled(false)


func set_toggled(value: bool) -> void:
	opened = value
	if opened:
		door_open_sound.play()
		if play_victory_fanfare_on_open:
			victory_sound.play()


func update_opened_state() -> void:
	%DoorClosed.visible = !opened
	%DoorOpened.visible = opened

	%ColliderWhenClosed.set_collision_layer_value(Enums.CollisionLayers.WALLS, not opened)
	%ColliderWhenClosed.set_collision_mask_value(Enums.CollisionLayers.PLAYERS, not opened)
