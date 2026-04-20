# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CheckButton
## A [CheckButton] that toggles a property of [Settings].

## The name of a property of the [Settings] singleton.
@export var setting: StringName:
	set = set_setting


func set_setting(new_value: StringName) -> void:
	setting = new_value
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not setting:
		warnings.append("Setting name is not set.")
	elif setting not in Settings:
		warnings.append("Settings singleton has no property named " + setting)

	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# There are two instances of this toggle in the game: one on the title screen, and
	# another in the pause overlay. At most one is displayed at a time, so we can keep them in
	# synch by reading the setting each time each toggle is displayed.
	visibility_changed.connect(_refresh)
	_refresh()

	toggled.connect(_on_toggled)


func _refresh() -> void:
	set_pressed_no_signal(Settings.get(setting))


func _on_toggled(toggled_on: bool) -> void:
	Settings.set(setting, toggled_on)
