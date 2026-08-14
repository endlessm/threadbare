# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var whole_scene_camera: PhantomCamera2D
@export var void_layer: TileMapCover
@export var collectible_thread: CollectibleItem
@export var enemy: CharacterBody2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func is_enemy_defeated() -> bool:
	return not is_instance_valid(enemy)


func repel_void() -> void:
	whole_scene_camera.priority += 20
	animation_player.play(&"retreat")
	await animation_player.animation_finished
	await collectible_thread.reveal()
	whole_scene_camera.priority -= 20
