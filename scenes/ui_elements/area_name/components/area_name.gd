# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export_multiline var zone_name: String

@export_range(1, 3) var time: int = 2


func _on_detect_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if GameState.global.current_area_name == zone_name:
		return

	GameState.global.current_area_name = zone_name

	GameState.global.set_unlock_area(zone_name)
	GameState.save()
