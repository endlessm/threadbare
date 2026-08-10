# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var arrow: PackedScene
@export var time: float = 1.0

@onready var cooldown: Timer = $Cooldown


func _ready() -> void:
	cooldown.wait_time = time


func shoot():
	var arr = arrow.instantiate()
	arr.spawn_pos = global_position
	owner.add_child(arr)


func _on_cooldown_timeout() -> void:
	shoot()
