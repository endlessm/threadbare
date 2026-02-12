# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@onready var TMLs: Node2D = $"../.."
@onready var target_z_index: int = $"..".z_index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	prints("Moving player to level", target_z_index)
	body.z_index = target_z_index

	for level in TMLs.get_children():
		var blocking_water := level.get_node("BlockingWater")
		blocking_water.collision_enabled = level.z_index == target_z_index
