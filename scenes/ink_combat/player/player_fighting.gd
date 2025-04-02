# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const SPLASH: PackedScene = preload("res://scenes/ink_combat/splash/splash.tscn")
const HARM: float = 0.2

var health: float = 1.0
var is_fighting: bool = false

@onready var hit_box: Area2D = %HitBox
@onready var health_bar: ProgressBar = %HealthBar
@onready var got_hit_animation: AnimationPlayer = %GotHitAnimation


func _ready() -> void:
	hit_box.body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
	elif Input.is_action_just_released(&"ui_accept"):
		is_fighting = false


func _on_body_entered(body: Node2D) -> void:
	body = body as InkBlob
	if not body:
		return
	body.queue_free()
	health -= HARM
	health_bar.visible = true
	health_bar.value = clamp(health, 0., 1.)
	got_hit_animation.play(&"got_hit")
	if health <= 0.:
		# Restart the minigame.
		get_tree().reload_current_scene()
	else:
		var splash: Splash = SPLASH.instantiate()
		splash.ink_color_name = body.ink_color_name
		get_tree().current_scene.add_child(splash)
		splash.global_position = body.global_position
