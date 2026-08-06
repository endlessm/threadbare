# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorDebuggerPlugin
## Handles Threadbare specific messages sent by the running game through [EngineDebugger].

## Prefix of the messages handled by this plugin.
const CAPTURE_PREFIX := "threadbare_debugger"


func _has_capture(capture: String) -> bool:
	return capture == CAPTURE_PREFIX


func _capture(message: String, data: Array, _session_id: int) -> bool:
	# The messages arrive with the prefix.
	match message.trim_prefix(CAPTURE_PREFIX + ":"):
		"open_scene_file":
			if data.is_empty():
				push_error("open_scene_file: expected a scene path as first argument.")
				return true
			var file_path := data[0] as String
			if file_path and file_path.ends_with(".tscn"):
				EditorInterface.open_scene_from_path(file_path)
			return true
	return false
