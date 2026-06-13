# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

## Factor to reduce the shooting period.
## Using 0.52 with a 4.0s start will reach ~1.1s by the 2nd vase.
@export_range(0.01, 1.0, 0.01) var speed_factor: float = 0.52


func _ready() -> void:
	var barrels: Array[Node] = get_tree().get_nodes_in_group("filling_barrels")

	for barrel: Node in barrels:
		if barrel is FillingBarrel:
			barrel.completed.connect(_on_barrel_completed)


func _on_barrel_completed() -> void:
	_increase_enemies_speed()


func _increase_enemies_speed() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("throwing_enemy")

	for enemy_node: Node in enemies:
		if is_instance_valid(enemy_node) and enemy_node is ThrowingEnemy:
			var enemy: ThrowingEnemy = enemy_node as ThrowingEnemy

			# Calculate the new faster period
			var new_period: float = enemy.throwing_period * speed_factor

			# SAFETY LOCK: Clamp the value so it never goes below 1.05 seconds.
			# This prevents the animation (which lasts 1.0s) from breaking.
			enemy.throwing_period = max(new_period, 1.05)
