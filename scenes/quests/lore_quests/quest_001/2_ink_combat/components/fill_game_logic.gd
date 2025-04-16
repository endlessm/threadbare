# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name FillGameLogic
extends Node

signal goal_reached

@export var barrels_to_win: int = 1

var barrels_completed: int = 0


func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING
	get_tree().call_group("throwing_enemy", "start")
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		filling_barrel.completed.connect(_on_barrel_completed)
	_update_allowed_colors()


func _update_allowed_colors() -> void:
	var allowed_labels: Array[String] = []
	var color_per_label: Dictionary[String, Color]
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		if filling_barrel.is_queued_for_deletion():
			continue
		if filling_barrel.label not in allowed_labels:
			allowed_labels.append(filling_barrel.label)
			if not filling_barrel.color:
				continue
			color_per_label[filling_barrel.label] = filling_barrel.color
	for enemy: ThrowingEnemy in get_tree().get_nodes_in_group("throwing_enemy"):
		enemy.allowed_labels = allowed_labels
		enemy.color_per_label = color_per_label


func _on_barrel_completed() -> void:
	barrels_completed += 1
	_update_allowed_colors()
	if barrels_completed < barrels_to_win:
		return
	get_tree().call_group("throwing_enemy", "remove")
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY
	goal_reached.emit()
