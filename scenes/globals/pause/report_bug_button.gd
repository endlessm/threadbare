# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Button
## Opens a bug report form in the web browser when clicked.

const Version := preload("res://addons/threadbare_git_describe/version.gd")
const URL_BASE := "https://github.com/endlessm/threadbare/issues/new?template=bug.yml"


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	var url := URL_BASE

	var version := Version.get_version()
	if version:
		url += "&version=" + version.uri_encode()

	var current_scene := get_tree().current_scene
	if current_scene:
		url += "&scene=" + current_scene.scene_file_path.uri_encode()

	OS.shell_open(url)
