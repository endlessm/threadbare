# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CollisionShape2D


func _on_area_2d_body_entered(body):
	if body.is_in_group("obstacle"):
		get_tree().reload_current_scene()
