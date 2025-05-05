# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@onready var transition_fade: ColorRect = %TransitionFade


func _ready() -> void:
	await create_tween().tween_property(transition_fade, "color:a", 0.0, 0.5).from(1.0).finished
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self.on_player_detected)


func on_player_detected(player: Node2D) -> void:
	player.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	await get_tree().create_timer(2.0).timeout
	await create_tween().tween_property(transition_fade, "color:a", 1.0, 0.5).finished
	get_tree().reload_current_scene()
