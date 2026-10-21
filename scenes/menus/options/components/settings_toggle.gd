# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CheckButton
## A [CheckButton] that toggles a property of [Settings].

## Cases in which a toggle is visible. See [member Settings.touch_controls].
enum VisibleWhen {
	## Always visible.
	ALWAYS,
	## Visible while not using the touch controls, for settings that don't apply
	## to touch.
	NOT_IN_TOUCH_MODE,
	## Visible when the player can choose between touch and keyboard. See
	## [method Settings.can_choose_touch_controls].
	TOUCH_CHOICE_AVAILABLE,
}

## The name of a property of the [Settings] singleton.
@export var setting: StringName:
	set = set_setting

## When this toggle is visible.
@export var visible_when: VisibleWhen = VisibleWhen.ALWAYS


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
	# Fullscreen can also change outside the game, for example when the player
	# presses Esc in a browser. The window is resized when that happens.
	get_window().size_changed.connect(_refresh)
	_refresh()

	toggled.connect(_on_toggled)

	if visible_when != VisibleWhen.ALWAYS:
		Settings.touch_controls_changed.connect(_update_visibility)
		_update_visibility()


func _update_visibility() -> void:
	match visible_when:
		VisibleWhen.NOT_IN_TOUCH_MODE:
			visible = not Settings.touch_controls
		VisibleWhen.TOUCH_CHOICE_AVAILABLE:
			visible = Settings.can_choose_touch_controls()


func _refresh() -> void:
	set_pressed_no_signal(Settings.get(setting))


func _on_toggled(toggled_on: bool) -> void:
	Settings.set(setting, toggled_on)
