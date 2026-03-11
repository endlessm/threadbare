# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var player: Player = %Player


func _on_void_quest_unlocker_toggled(satisfied: bool) -> void:
	if satisfied:
		player.mode = Player.Mode.HOOKING
	else:
		player.mode = Player.Mode.COZY
