# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var speed := 350.0
@export var direction := Vector2.LEFT
@export var label := "boss_projectile"

func _ready():
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D):
	if area.has_method("reflect_projectile"):
		area.reflect_projectile(self)

func _on_body_entered(body: Node):
	queue_free()
func got_hit(attacker):
	# invertir dirección hacia el boss
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		direction = (boss.global_position - global_position).normalized()
		speed *= 1.2
