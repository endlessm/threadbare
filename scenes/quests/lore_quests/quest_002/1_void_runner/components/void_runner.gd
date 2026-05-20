# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var enemy: CharacterBody2D = %VoidSpreadingEnemy


func is_enemy_defeated() -> bool:
	return not is_instance_valid(enemy)
