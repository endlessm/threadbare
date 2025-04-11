# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const SPLASH: PackedScene = preload(
	"res://scenes/quests/lore_quests/quest_001/2_ink_combat/components/splash/splash.tscn"
)

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
	body = body as InkBlob
	if not body:
		return
	body.queue_free()
	got_hit_animation.play(&"got_hit")
	var splash: Splash = SPLASH.instantiate()
	splash.ink_color_name = body.ink_color_name
	get_tree().current_scene.add_child(splash)
	splash.global_position = body.global_position
