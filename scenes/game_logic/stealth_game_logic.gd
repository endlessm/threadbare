# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)


func _on_player_detected(player: Player) -> void:
	player.defeat()
