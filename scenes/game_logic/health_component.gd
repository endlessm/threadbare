# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HealthComponent
extends Node2D

signal health_depleted
signal health_changed(current_health: int)

@export_range(1, 100) var max_health: int = 4

var current_health: int = max_health:
	set(value):
		if value == current_health:
			pass

		current_health = value
		if current_health <= 0:
			health_depleted.emit()
		else:
			health_changed.emit(current_health)

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
