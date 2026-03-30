# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends EditorExportPlugin

const Version = preload("./version.gd")


func _get_name() -> String:
	return "threadbare_git_describe_exporter"


func set_version(version: Variant) -> void:
	ProjectSettings.set_setting("application/config/version", version)
	var err := ProjectSettings.save()
	if err != OK:
		printerr("Failed to save project settings: %s" % error_string(err))


func _export_begin(
	_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int
) -> void:
	set_version(Version.git_describe(true))


func _export_end() -> void:
	set_version(null)
