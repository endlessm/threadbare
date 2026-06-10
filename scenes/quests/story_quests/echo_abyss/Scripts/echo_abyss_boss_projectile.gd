# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EchoAbyssBossProjectile
extends Projectile

@export var damage := 1

# Bandera para evitar aplicar daño dos veces si ambos handlers
# (body_entered del RigidBody2D y body_entered del HitBox Area2D) se disparan.
var _damage_applied: bool = false

func _ready() -> void:
	super._ready()
	# Conectamos body_entered para detectar al CharacterBody2D del player (capa 1).
	# La escena echo_abyss_projectile.tscn tiene collision_mask=81 para incluir capa 1.
	if not body_entered.is_connected(_on_boss_body_entered):
		body_entered.connect(_on_boss_body_entered)

## Se dispara cuando el proyectil colisiona con el CharacterBody2D del player.
func _on_boss_body_entered(body: Node) -> void:
	if _damage_applied or not can_hit_player:
		return
	var player := body as EchoAbyssPlayer
	if player:
		_damage_applied = true
		player.take_damage(damage)
		queue_free()

func got_repelled(repel_direction: Vector2) -> void:
	can_hit_enemy = true
	can_hit_player = true
	super.got_repelled(repel_direction)
