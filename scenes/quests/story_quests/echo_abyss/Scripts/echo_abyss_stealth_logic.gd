# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export_range(1, 10, 1) var damage_per_detection: int = 1
@export_range(0.0, 10.0, 0.1, "suffix:s") var detection_damage_cooldown: float = 1.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var guard_reset_delay: float = 0.7

var _can_damage := true


func _ready() -> void:
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(_on_guard_player_detected.bind(guard))


func _on_guard_player_detected(player: Node2D, guard: Guard) -> void:
	if _can_damage and player.has_method("take_damage"):
		player.call("take_damage", damage_per_detection)
		_start_damage_cooldown()

	await get_tree().create_timer(guard_reset_delay).timeout
	if is_instance_valid(guard):
		_reset_guard(guard)


func _start_damage_cooldown() -> void:
	_can_damage = false
	await get_tree().create_timer(detection_damage_cooldown).timeout
	_can_damage = true


func _reset_guard(guard: Guard) -> void:
	guard.call("_reset")
	guard.state = Guard.State.PATROLLING
	if guard.player_awareness:
		guard.player_awareness.value = 0
		guard.player_awareness.visible = false
