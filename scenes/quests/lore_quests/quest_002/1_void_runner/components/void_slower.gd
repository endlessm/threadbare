# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@onready var void_spreading_enemy: CharacterBody2D = $"../../../VoidSpreadingEnemy"


func is_void_alive() -> bool:
	return is_instance_valid(void_spreading_enemy)


func slowdown_void() -> void:
	if not is_void_alive():
		return
	var result := void_spreading_enemy.get_node_and_resource(
		"NavigationFollowWalkBehavior:speeds:walk_speed"
	)
	result[1].set("walk_speed", 100)
	result[1].set("run_speed", 200)
