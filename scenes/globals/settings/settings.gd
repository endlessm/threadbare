# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const SETTINGS_PATH := "user://settings.cfg"

const VOLUME_SECTION := "Volume"
const MIN_VOLUME := -30.0
const DEFAULT_VOLUMES: Dictionary[String, float] = {
	"Music": -15.0,
}

const VIDEO_SECTION := "Video"
const VIDEO_WINDOW_MODE_KEY := "Window Mode"

## 5:4 ratio of 1280×1024, 1024×768, and other pre-widescreen monitors.
const MINIMUM_ASPECT_RATIO := 1.25

## An arbitrary wide ratio, lower than 21:9 ("ultrawide").
const MAXIMUM_ASPECT_RATIO := 2.2

var _settings := ConfigFile.new()


func _ready() -> void:
	var err := _settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [SETTINGS_PATH, err])

	_restore_volumes()
	_restore_video_settings()
	_set_minimum_window_size()


func _restore_volumes() -> void:
	for bus_idx in AudioServer.bus_count:
		var bus := AudioServer.get_bus_name(bus_idx)
		var volume_db: float = _settings.get_value(
			VOLUME_SECTION, bus, DEFAULT_VOLUMES.get(bus, 0.0)
		)
		_set_volume(bus_idx, volume_db)


func _restore_video_settings() -> void:
	var default_window_mode: int = ProjectSettings.get_setting("display/window/size/mode")
	var window_mode: int = (
		_settings
		. get_value(
			VIDEO_SECTION,
			VIDEO_WINDOW_MODE_KEY,
			default_window_mode,
		)
	)
	if window_mode == DisplayServer.window_get_mode():
		return
	DisplayServer.window_set_mode(window_mode)


func _set_minimum_window_size() -> void:
	var minimum_window_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	get_window().min_size = minimum_window_size


func get_volume(bus: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus)

	return AudioServer.get_bus_volume_db(bus_idx)


func set_volume(bus: String, volume_db: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	_set_volume(bus_idx, volume_db)

	_settings.set_value(VOLUME_SECTION, bus, volume_db)
	_save()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func toggle_fullscreen(toggled_on: bool) -> void:
	var default_window_mode: int = ProjectSettings.get_setting("display/window/size/mode")
	set_window_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else default_window_mode)


func set_window_mode(window_mode: int) -> void:
	if window_mode == DisplayServer.window_get_mode():
		return
	DisplayServer.window_set_mode(window_mode)
	_settings.set_value(VIDEO_SECTION, VIDEO_WINDOW_MODE_KEY, window_mode)
	_save()


func _set_volume(bus_idx: int, volume_db: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	var mute := volume_db <= MIN_VOLUME
	AudioServer.set_bus_mute(bus_idx, mute)


func _save() -> void:
	var err := _settings.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [SETTINGS_PATH, err])
