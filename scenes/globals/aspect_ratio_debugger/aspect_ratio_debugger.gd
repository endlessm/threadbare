# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer


func _ready() -> void:
	if not ProjectSettings.get_setting(ThreadbareProjectSettings.DEBUG_ASPECT_RATIO):
		queue_free()
