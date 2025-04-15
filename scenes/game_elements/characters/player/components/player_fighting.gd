# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var is_fighting: bool = false

@onready var hit_box: Area2D = %HitBox
@onready var got_hit_animation: AnimationPlayer = %GotHitAnimation


func _ready() -> void:
	hit_box.body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if %PlayerController.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
	elif %PlayerController.is_action_just_released(&"ui_accept"):
		is_fighting = false


func _on_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return
	body.add_splash()
	body.queue_free()
	got_hit_animation.play(&"got_hit")
