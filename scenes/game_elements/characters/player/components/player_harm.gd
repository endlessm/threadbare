# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## The player hitbox area.
@onready var hit_box: Area2D = %HitBox

## Animation to play when the player gets hit.
@onready var got_hit_animation: AnimationPlayer = %GotHitAnimation


func _on_hit_box_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return
	body.add_small_fx()
	body.queue_free()
	got_hit_animation.play(&"got_hit")
	CameraShake.shake()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			got_hit_animation.play(&"RESET")
			got_hit_animation.advance(0)
