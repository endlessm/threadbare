# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThreadbareEditorPlugin
extends EditorPlugin

const ThreadbareDebugger := preload("res://addons/threadbare_editor/threadbare_debugger.gd")

var threadbare_debugger: EditorDebuggerPlugin


func _enter_tree() -> void:
	threadbare_debugger = ThreadbareDebugger.new()
	add_debugger_plugin(threadbare_debugger)


func _exit_tree() -> void:
	if threadbare_debugger:
		remove_debugger_plugin(threadbare_debugger)
		threadbare_debugger = null
