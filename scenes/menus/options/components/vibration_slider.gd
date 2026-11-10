# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends HSlider
## A slider for [member Settings.vibration_strength].
##
## When moved, the joypad vibrates briefly at the new strength, so the player
## can feel the result.

## How long the vibration lasts when the slider is moved, in seconds.
const PREVIEW_DURATION := 0.2

## Control to hide where joypad vibration is not supported, for example the
## row containing this slider and its label. If not set, only the slider hides.
@export var container: Control


func _ready() -> void:
	# The web platform can't vibrate joypads, only phones. Joypad vibration
	# goes through the SDL driver, which only the native builds use.
	if OS.has_feature("web"):
		(container if container else self).hide()
		return

	# There are two instances of this slider in the game: one on the title screen, and
	# another in the pause overlay. At most one is displayed at a time, so we can keep them in
	# synch by reading the setting each time the slider is displayed.
	visibility_changed.connect(_refresh)
	_refresh()

	value_changed.connect(_on_value_changed)


func _refresh() -> void:
	if visible:
		set_value_no_signal(Settings.vibration_strength)


func _on_value_changed(new_value: float) -> void:
	Settings.vibration_strength = new_value
	JoypadVibration.start(InputHelper.device_index, 0.5, 0.5, PREVIEW_DURATION)
