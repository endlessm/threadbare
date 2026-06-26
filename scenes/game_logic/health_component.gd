# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HealthComponent
extends Node

## Emitted when [member current_health] reaches zero.
signal health_depleted

## Emitted when [member current_health] changes.[br]
## Is not emitted when the health reaches zero, [signal health_depleted] is emitted instead.
signal health_changed(current_health: int)

@export_range(1, 100) var max_health: int = 4

## Represents the current health.[br]
## The value will always be in the following range [code]0 <= current_health <= max_health[/code].
var current_health: int = max_health:
	set(value):
		if value == current_health:
			return

		current_health = clamp(value, 0, max_health)
		if current_health <= 0:
			health_depleted.emit()
		else:
			health_changed.emit(current_health)

var damage_taken: int:
	get:
		return max_health - current_health

var damage_taken_ratio: float:
	get:
		return float(damage_taken) / max_health

var has_depleted_health: bool:
	get:
		return current_health <= 0


func damage(amount: int) -> void:
	current_health -= amount


func heal(amount: int) -> void:
	current_health += amount
