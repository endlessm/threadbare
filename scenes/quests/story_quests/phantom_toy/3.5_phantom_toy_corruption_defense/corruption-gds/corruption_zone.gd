# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CorruptionZone
extends Node2D

@export_range(0.0, 100.0)
var corruption: float = 0.0
@export var altar: Altar
var player_inside := false


func increase_corruption(amount: float) -> void:
	corruption = min(corruption + amount, 100.0)


func decrease_corruption(amount: float) -> void:
	corruption = max(corruption - amount, 0.0)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
		print(name, " player entered")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
