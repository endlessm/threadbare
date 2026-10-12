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

	var version := Version.get_full_version()
	if version:
		url += "&version=" + version.uri_encode()

	var current_scene := get_tree().current_scene
	if current_scene:
		url += "&scene=" + current_scene.scene_file_path.uri_encode()

	var game_resolution := DisplayServer.window_get_size()
	if game_resolution:
		url += "&resolution=" + ("%sx%s" % [game_resolution.x, game_resolution.y])

	var player := get_tree().get_first_node_in_group("player")
	if player:
		url += (
			"&location="
			+ (
				("%s,%s" % [player.get_global_position().x, player.get_global_position().y])
				. uri_encode()
			)
		)

	OS.shell_open(url)
