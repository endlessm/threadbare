# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Decoration


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		var y_scale := randf_range(0.8, 1.2)
		var x_scale := y_scale * randf_range(0.9, 1.1)
		scale = Vector2(x_scale, y_scale)
