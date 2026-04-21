# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin


func _enter_tree() -> void:
	ThreadbareProjectSettings.setup_threadbare_settings()
