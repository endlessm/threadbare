# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends EditorExportPlugin

const Version = preload("./version.gd")


func _get_name() -> String:
	return "threadbare_git_describe_exporter"


func _export_begin(
	_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int
) -> void:
	var describe := Version.git_describe(true)
	ProjectSettings.set_setting(Version.FULL_VERSION_KEY, describe)
	ProjectSettings.set_setting(Version.VERSION_KEY, Version.simplify(describe))
	var err := ProjectSettings.save()
	if err != OK:
		printerr("Failed to save project settings: %s" % error_string(err))


func _export_end() -> void:
	ProjectSettings.set_setting(Version.FULL_VERSION_KEY, null)
	ProjectSettings.set_setting(Version.VERSION_KEY, null)
	var err := ProjectSettings.save()
	if err != OK:
		printerr("Failed to save project settings: %s" % error_string(err))
