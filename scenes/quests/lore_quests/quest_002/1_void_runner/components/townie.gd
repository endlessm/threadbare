# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends NPC

@export var enemy: CharacterBody2D


func is_enemy_defeated() -> bool:
	return not is_instance_valid(enemy)
