# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		scale = Vector2(randf_range(0.8, 1.2), randf_range(0.8, 1.2))
