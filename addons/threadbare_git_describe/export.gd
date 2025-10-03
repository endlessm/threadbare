# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends EditorExportPlugin


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
	var output: Array[String] = []
	var ret := OS.execute("git", ["describe", "--tags"], output)
	if ret != 0:
		printerr("git describe --tags failed: %d" % ret)
	else:
		var version := output[0].strip_edges()
		set_version(version)


func _export_end() -> void:
	set_version(null)
