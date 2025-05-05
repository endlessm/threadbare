# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _ready() -> void:
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self.on_player_detected)


func on_player_detected(player: Node2D) -> void:
	player.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	await get_tree().create_timer(2.0).timeout
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
