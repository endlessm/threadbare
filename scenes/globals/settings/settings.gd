# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const SETTINGS_PATH := "user://settings.cfg"

const VOLUME_SECTION := "Volume"
const MIN_VOLUME := -30.0
const DEFAULT_VOLUMES: Dictionary[String, float] = {
	"Music": -15.0,
}

var _settings := ConfigFile.new()


func _ready() -> void:
	var err := _settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		print("Failed to load %s: %s" % [SETTINGS_PATH, err])

	_restore_volumes()


func _restore_volumes() -> void:
	for bus_idx in AudioServer.bus_count:
		var bus := AudioServer.get_bus_name(bus_idx)
		var volume_db: float = _settings.get_value(
			VOLUME_SECTION, bus, DEFAULT_VOLUMES.get(bus, 0.0)
		)
		print("Restored", [bus_idx, bus, volume_db])
		_set_volume(bus_idx, volume_db)


func get_volume(bus: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus)

	return AudioServer.get_bus_volume_db(bus_idx)


func set_volume(bus: String, volume_db: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	_set_volume(bus_idx, volume_db)

	_settings.set_value(VOLUME_SECTION, bus, volume_db)
	_save()


func _set_volume(bus_idx: int, volume_db: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	var mute := volume_db <= MIN_VOLUME
	AudioServer.set_bus_mute(bus_idx, mute)


func _save() -> void:
	var err := _settings.save(SETTINGS_PATH)
	if err != OK:
		print("Failed to save settings to %s: %s" % [SETTINGS_PATH, err])
