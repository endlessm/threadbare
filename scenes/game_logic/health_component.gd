# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HealthComponent
extends Node2D

signal health_depleted
signal health_changed(current_health: int, has_depleted_health: bool)

@export_range(1, 100) var max_health: int = 4

var current_health: int = max_health:
	set(value):
		var old_health: int = current_health
		current_health = value
		if value <= 0:
			health_depleted.emit()
		elif value != old_health:
			health_changed.emit(value, has_depleted_health)

var damage_taken: int:
	get:
		return max_health - current_health

var damage_taken_percentage: float:
	get:
		return float(damage_taken) / max_health

var has_depleted_health: bool:
	get:
		return current_health <= 0


func damage(amount: int) -> void:
	current_health -= amount


func heal(amount: int) -> void:
	current_health += amount
