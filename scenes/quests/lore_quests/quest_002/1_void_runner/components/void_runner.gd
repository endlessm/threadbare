# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var whole_scene_camera: PhantomCamera2D
@export var void_layer: TileMapCover
@export var collectible_thread: CollectibleItem
@export var enemy: CharacterBody2D


func is_enemy_defeated() -> bool:
	return not is_instance_valid(enemy)


func repel_void() -> void:
	whole_scene_camera.priority += 20
	await void_layer.uncover_all(3.0)
	await collectible_thread.reveal()
	whole_scene_camera.priority -= 20
