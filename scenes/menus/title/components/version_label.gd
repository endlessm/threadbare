# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label


func _ready() -> void:
	text = ProjectSettings.get(&"application/config/version")
