# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InkDrinker
extends CharacterBody2D

const INK_BLOB: PackedScene = preload("res://scenes/ink_combat/ink_blob/ink_blob.tscn")
const BIG_SPLASH: PackedScene = preload("res://scenes/ink_combat/big_splash/big_splash.tscn")

@export var odd_shoot: bool = false
@export var ink_follows_player: bool = false
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var ink_speed: float = 30.0

@onready var timer: Timer = %Timer

@onready var ink_blob_marker: Marker2D = %InkBlobMarker
@onready var hit_box: Area2D = %HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	timer.timeout.connect(_on_timeout)
	hit_box.body_entered.connect(_on_got_hit)
	if odd_shoot:
		await get_tree().create_timer(timer.wait_time / 2).timeout
	timer.start()


func _on_timeout() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	animated_sprite_2d.play(&"attack anticipation")
	await animated_sprite_2d.animation_looped
	animated_sprite_2d.play(&"attack")
	var ink_blob: InkBlob = INK_BLOB.instantiate()
	ink_blob.direction = ink_blob_marker.global_position.direction_to(player.global_position)
	ink_blob.ink_color_name = randi_range(0, 3) as InkBlob.InkColorNames
	ink_blob.global_position = (ink_blob_marker.global_position + ink_blob.direction * 20.)
	if ink_follows_player:
		ink_blob.node_to_follow = player
	ink_blob.speed = ink_speed
	get_tree().current_scene.add_child(ink_blob)
	await animated_sprite_2d.animation_looped
	animated_sprite_2d.play(&"idle")


func _on_got_hit(body: Node2D) -> void:
	if body is InkBlob and not body.can_hit_enemy:
		return
	body.queue_free()
	animation_player.play(&"got hit")


func explode(ink_color_name: InkBlob.InkColorNames = InkBlob.InkColorNames.CYAN) -> void:
	var big_splash: BigSplash = BIG_SPLASH.instantiate()
	big_splash.ink_color_name = ink_color_name
	get_tree().current_scene.add_child(big_splash)
	big_splash.global_position = global_position
	queue_free()
