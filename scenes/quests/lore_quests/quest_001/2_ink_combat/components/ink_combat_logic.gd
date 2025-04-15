# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InkCombatLogic
extends Node

signal goal_reached

@export var inkwells_to_win: int = 1

var inkwells_completed: int = 0


func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING
	get_tree().call_group("throwing_enemy", "start")
	for inkwell: Inkwell in get_tree().get_nodes_in_group("inkwells"):
		inkwell.completed.connect(_on_inkwell_completed)
	_update_allowed_colors()


func _update_allowed_colors() -> void:
	var allowed_colors: Array = []
	for inkwell: Inkwell in get_tree().get_nodes_in_group("inkwells"):
		if inkwell.is_queued_for_deletion():
			continue
		if inkwell.ink_color_name not in allowed_colors:
			allowed_colors.append(inkwell.ink_color_name)
	for enemy: ThrowingEnemy in get_tree().get_nodes_in_group("throwing_enemy"):
		enemy.allowed_colors = allowed_colors


func _on_inkwell_completed() -> void:
	inkwells_completed += 1
	_update_allowed_colors()
	if inkwells_completed < inkwells_to_win:
		return
	get_tree().call_group("throwing_enemy", "remove")
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY
	goal_reached.emit()
