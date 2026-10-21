# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

## Emitted when [member keyboard_only] changes.
signal keyboard_only_changed

const SETTINGS_PATH := "user://settings.cfg"

const META_SECTION := "Meta"
const VERSION_KEY := "Version"
const VERSION := 1

const VOLUME_SECTION := "Volume"

const DISPLAY_SECTION := "Display"
const SHOW_HUD_KEY := "Show HUD"
const LARGE_TEXT_KEY := "Large Text"

const INPUT_SECTION := "Input"
const KEYBOARD_ONLY_KEY := "Keyboard Only"
const VIBRATION_STRENGTH_KEY := "Vibration Strength"

const LANGUAGE_SECTION := "Language"
const LOCALE_KEY := "Locale"
const DEFAULT_LOCALE := "en"

## 5:4 ratio of 1280×1024, 1024×768, and other pre-widescreen monitors.
const MINIMUM_ASPECT_RATIO := 1.25

## An arbitrary wide ratio, lower than 21:9 ("ultrawide").
const MAXIMUM_ASPECT_RATIO := 2.2

## Screens whose shortest side is under this are considered small, like phones.
## This is the threshold that Android uses to tell phones from tablets.
const SMALL_SCREEN_SHORTEST_SIDE_DP := 600.0

@export var fullscreen: bool:
	get = is_fullscreen,
	set = set_fullscreen

@export var show_input_hud := true:
	get:
		return _settings.get_value(DISPLAY_SECTION, SHOW_HUD_KEY, true)
	set(new_value):
		_settings.set_value(DISPLAY_SECTION, SHOW_HUD_KEY, new_value)
		_save()

## Show the text of dialogues and signs with a bigger font. Unless the player
## changes it, this is on for small screens like phones, and off otherwise.
@export var large_text: bool:
	get:
		return _settings.get_value(DISPLAY_SECTION, LARGE_TEXT_KEY, is_small_screen())
	set(new_value):
		_settings.set_value(DISPLAY_SECTION, LARGE_TEXT_KEY, new_value)
		_save()

## Play with the keyboard only, instead of keyboard + mouse. This decides
## whether the mouse or the aim keys aim the grappling hook, and whether the
## input hints show the mouse buttons or the keys. It doesn't matter while
## playing with a joypad.
@export var keyboard_only: bool:
	get:
		return _settings.get_value(INPUT_SECTION, KEYBOARD_ONLY_KEY, false)
	set(new_value):
		_settings.set_value(INPUT_SECTION, KEYBOARD_ONLY_KEY, new_value)
		_save()
		keyboard_only_changed.emit()

## How strong the joypad vibrates, from 0.0 (off) to 1.0 (full strength).
## Use [method JoypadVibration.start] to vibrate the joypad with this applied.
@export_range(0.0, 1.0, 0.1) var vibration_strength: float = 1.0:
	get:
		var stored: float = _settings.get_value(INPUT_SECTION, VIBRATION_STRENGTH_KEY, 1.0)
		return clampf(stored, 0.0, 1.0)
	set(new_value):
		_settings.set_value(INPUT_SECTION, VIBRATION_STRENGTH_KEY, clampf(new_value, 0.0, 1.0))
		_save()

var _settings := ConfigFile.new()

var _overrides_path: String
var _overrides := ConfigFile.new()

var _default_volumes: Dictionary[String, float]


func _ready() -> void:
	var err := _settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [SETTINGS_PATH, err])

	var file_version: Variant = _settings.get_value(META_SECTION, VERSION_KEY, 0)
	if file_version != VERSION:
		_settings.clear()
	_settings.set_value(META_SECTION, VERSION_KEY, VERSION)

	_restore_volumes()
	_restore_locale()
	_load_project_settings_overrides()
	_set_minimum_window_size()


func _restore_volumes() -> void:
	for bus_idx in AudioServer.bus_count:
		var bus := AudioServer.get_bus_name(bus_idx)
		# The default bus layout volumes double as the max volumes
		var max_volume_linear := AudioServer.get_bus_volume_linear(bus_idx)
		_default_volumes[bus] = max_volume_linear
		var volume_linear: float = _settings.get_value(VOLUME_SECTION, bus, max_volume_linear)
		_set_volume(bus_idx, clampf(volume_linear, 0.0, max_volume_linear))


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


func get_max_volume(bus: String) -> float:
	return _default_volumes.get(bus, 1.0)


func set_volume(bus: String, volume_linear: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	_set_volume(bus_idx, volume_linear)

	_settings.set_value(VOLUME_SECTION, bus, volume_linear)
	_save()


func is_fullscreen() -> bool:
	# On the web, Godot reports the non-exclusive fullscreen mode instead.
	return (
		DisplayServer.window_get_mode()
		in [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN]
	)


func set_fullscreen(toggled_on: bool) -> void:
	if toggled_on:
		set_window_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		set_window_mode(DisplayServer.WINDOW_MODE_WINDOWED)


## Return true on touchscreen devices with a small screen, like phones, and
## false on tablets and desktops.
func is_small_screen() -> bool:
	if not DisplayServer.is_touchscreen_available():
		return false
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var shortest_side := minf(screen_size.x, screen_size.y)
	var shortest_side_dp: float
	if OS.has_feature("web"):
		# On the web, the screen size divided by the scale is in CSS pixels,
		# which are close to density-independent pixels. The DPI can't be used,
		# because browsers derive it from the scale instead of the real screen.
		shortest_side_dp = shortest_side / DisplayServer.screen_get_scale()
	else:
		# Density-independent pixels are 1/160 inch.
		shortest_side_dp = shortest_side * 160.0 / DisplayServer.screen_get_dpi()
	return shortest_side_dp < SMALL_SCREEN_SHORTEST_SIDE_DP


func get_locale() -> String:
	return TranslationServer.get_locale()


func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	_settings.set_value(LANGUAGE_SECTION, LOCALE_KEY, locale)
	_save()


func set_window_mode(window_mode: int) -> void:
	if window_mode == DisplayServer.window_get_mode():
		return
	DisplayServer.window_set_mode(window_mode)

	if _overrides_path:
		_overrides.set_value("display", "window/size/mode", window_mode)
		var ret := _overrides.save(_overrides_path)
		if ret != OK:
			push_warning("Failed to save to", _overrides_path, ": ", error_string(ret))


func _restore_locale() -> void:
	var locale: String = _settings.get_value(LANGUAGE_SECTION, LOCALE_KEY, DEFAULT_LOCALE)
	TranslationServer.set_locale(locale)


func _set_volume(bus_idx: int, volume_linear: float) -> void:
	AudioServer.set_bus_volume_linear(bus_idx, volume_linear)


func _save() -> void:
	var err := _settings.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [SETTINGS_PATH, err])
