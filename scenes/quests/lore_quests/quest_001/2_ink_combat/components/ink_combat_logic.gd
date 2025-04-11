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
	get_tree().call_group("ink_drinkers", "start")
	for inkwell: Inkwell in get_tree().get_nodes_in_group("inkwells"):
		inkwell.completed.connect(_on_inkwell_completed)


func _on_inkwell_completed() -> void:
	inkwells_completed += 1
	if inkwells_completed < inkwells_to_win:
		return
	get_tree().call_group("ink_drinkers", "remove")
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY
	goal_reached.emit()
