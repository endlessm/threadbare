# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name RunaRunnerFinalEnergyProjectile
extends Area2D

signal hit_player(projectile: RunaRunnerFinalEnergyProjectile)

@export var speed: float = 260.0
@export var lifetime: float = 5.0
@export var damage: float = 16.0

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func setup(
	start_position: Vector2, shoot_direction: Vector2, new_speed: float, new_damage: float
) -> void:
	global_position = start_position
	direction = shoot_direction.normalized() if shoot_direction.length_squared() > 0.0 else Vector2.RIGHT
	speed = new_speed
	damage = new_damage
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	_age += delta
	global_position += direction * speed * delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		hit_player.emit(self)
		queue_free()
