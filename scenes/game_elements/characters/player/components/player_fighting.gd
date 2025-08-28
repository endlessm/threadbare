# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var is_fighting: bool = false

@onready var hit_box: Area2D = %HitBox
@onready var got_hit_animation: AnimationPlayer = %GotHitAnimation
@onready var air_stream: Area2D = %AirStream
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite

@onready var player: Player = self.owner as Player


func _ready() -> void:
	hit_box.body_entered.connect(_on_body_entered)
	air_stream.body_entered.connect(_on_air_stream_body_entered)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"repel"):
		is_fighting = true
	elif Input.is_action_just_released(&"repel"):
		is_fighting = false


func _on_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return
	body.add_small_fx()
	body.queue_free()
	got_hit_animation.play(&"got_hit")
	CameraShake.shake()


func _on_air_stream_body_entered(body: Projectile) -> void:
	body.got_hit(owner)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			got_hit_animation.play(&"RESET")
			got_hit_animation.advance(0)
