# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const Export := preload("export.gd")

var export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	export_plugin = Export.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
