# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const CreditsImportPlugin := preload("./import_plugin.gd")

var _import_plugin: CreditsImportPlugin


func _enter_tree() -> void:
	_import_plugin = CreditsImportPlugin.new()
	add_import_plugin(_import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(_import_plugin)
	_import_plugin = null
