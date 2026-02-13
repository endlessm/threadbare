# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const SETTINGS_PATH := "user://settings.cfg"

const META_SECTION := "Meta"
const VERSION_KEY := "Version"
const VERSION := 1

const VOLUME_SECTION := "Volume"
const MIN_VOLUME := 0.0
const MAX_VOLUME := 1.0
const DEFAULT_VOLUMES: Dictionary[String, float] = {
	"Music": 0.5,
}

## 5:4 ratio of 1280×1024, 1024×768, and other pre-widescreen monitors.
const MINIMUM_ASPECT_RATIO := 1.25

## An arbitrary wide ratio, lower than 21:9 ("ultrawide").
const MAXIMUM_ASPECT_RATIO := 2.2

var _settings := ConfigFile.new()

var _overrides_path: String
var _overrides := ConfigFile.new()


func _ready() -> void:
	var err := _settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [SETTINGS_PATH, err])

	var file_version: Variant = _settings.get_value(META_SECTION, VERSION_KEY, 0)
	if file_version != VERSION:
		_settings.clear()
	_settings.set_value(META_SECTION, VERSION_KEY, VERSION)

	_restore_volumes()
	_load_project_settings_overrides()
	_set_minimum_window_size()


func _restore_volumes() -> void:
	for bus_idx in AudioServer.bus_count:
		var bus := AudioServer.get_bus_name(bus_idx)
		var volume_linear: float = _settings.get_value(
			VOLUME_SECTION, bus, DEFAULT_VOLUMES.get(bus, MAX_VOLUME)
		)

		_set_volume(bus_idx, volume_linear)


func _load_project_settings_overrides() -> void:
	_overrides_path = ProjectSettings.globalize_path(
		ProjectSettings.get_setting("application/config/project_settings_override")
	)
	print_verbose("Project settings override path: ", _overrides_path)
	if _overrides_path:
		var ret := _overrides.load(_overrides_path)
		match ret:
			OK, ERR_FILE_NOT_FOUND:
				pass
			_:
				push_warning("Failed to load ", _overrides_path, ": ", error_string(ret))
	else:
		push_warning("project_settings_override not configured")


func _set_minimum_window_size() -> void:
	var minimum_window_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	get_window().min_size = minimum_window_size


func get_volume(bus: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus)

	return AudioServer.get_bus_volume_linear(bus_idx)


func set_volume(bus: String, volume_linear: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	_set_volume(bus_idx, volume_linear)

	_settings.set_value(VOLUME_SECTION, bus, volume_linear)
	_save()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func toggle_fullscreen(toggled_on: bool) -> void:
	if toggled_on:
		set_window_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		set_window_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_window_mode(window_mode: int) -> void:
	if window_mode == DisplayServer.window_get_mode():
		return
	DisplayServer.window_set_mode(window_mode)

	if _overrides_path:
		_overrides.set_value("display", "window/size/mode", window_mode)
		var ret := _overrides.save(_overrides_path)
		if ret != OK:
			push_warning("Failed to save to", _overrides_path, ": ", error_string(ret))


func _set_volume(bus_idx: int, volume_linear: float) -> void:
	AudioServer.set_bus_volume_linear(bus_idx, volume_linear)


func _save() -> void:
	var err := _settings.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [SETTINGS_PATH, err])
