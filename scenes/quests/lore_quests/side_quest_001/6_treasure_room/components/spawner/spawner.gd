# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var arrow: PackedScene


func shoot():
	var arr = arrow.instantiate()
	arr.spawn_pos = global_position
	owner.add_child(arr)


func _on_cooldown_timeout() -> void:
	shoot()
