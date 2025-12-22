# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const LongerHook = preload(
	"res://scenes/quests/lore_quests/quest_002/2_grappling_hook/components/longer_hook.gd"
)

@onready var player: Player = %Player
@onready var frame_camera_behavior: FrameCameraBehavior = %FrameCameraBehavior
@onready var void_chasing: CharacterBody2D = %VoidChasing


func _ready() -> void:
	frame_camera_behavior.frame_target = player.get_node("PlayerHook/HookEnding")


func _on_button_item_collected() -> void:
	LongerHook.grant_longer_hook(player)

	# Zoom out the camera when collecting the powerup, because now the player
	# can throw a longer thread:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(0.5, 0.5), 1.0)
	void_chasing.start(player)
