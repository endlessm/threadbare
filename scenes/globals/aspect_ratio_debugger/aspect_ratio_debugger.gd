# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer


func _ready() -> void:
	if not ProjectSettings.get_setting("threadbare/debugging/debug_aspect_ratio"):
		queue_free()
