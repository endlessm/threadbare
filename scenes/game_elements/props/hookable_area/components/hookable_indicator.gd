# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var bouncing := false:
	set = set_bouncing

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func set_bouncing(new_value: bool) -> void:
	bouncing = new_value
	if animation_player:
		animation_player.play(&"bounce" if new_value else &"idle")


func _ready() -> void:
	set_bouncing(bouncing)
