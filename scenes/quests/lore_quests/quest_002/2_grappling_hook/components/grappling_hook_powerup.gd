# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _on_longer_thread_powerup_collected() -> void:
	# Zoom out the camera when collecting the powerup, because now the player
	# can throw a longer thread:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(0.8, 0.8), 1.0)
