# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Button


func _ready() -> void:
	# This button only makes sense if the game is ran from the editor.
	visible = OS.has_feature("editor")
	if not visible:
		queue_free()


func _on_pressed() -> void:
	var file_path := get_tree().current_scene.scene_file_path
	if EngineDebugger.is_active():
		EngineDebugger.send_message("threadbare_debugger:open_scene_file", [file_path])
