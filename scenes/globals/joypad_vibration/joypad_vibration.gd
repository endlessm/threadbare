# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name JoypadVibration
## Vibrate joypads respecting the player's [member Settings.vibration_strength].
##
## Use [method start] instead of calling [method Input.start_joy_vibration]
## directly.


## Vibrate the joypad at [param device_index], with both motor strengths scaled
## by [member Settings.vibration_strength]. Does nothing when vibration is
## turned off, or when [param device_index] is not a joypad (-1).
static func start(
	device_index: int, weak_magnitude: float, strong_magnitude: float, duration: float = 0.0
) -> void:
	var strength := Settings.vibration_strength
	if device_index < 0 or strength <= 0.0:
		return
	Input.start_joy_vibration(
		device_index, weak_magnitude * strength, strong_magnitude * strength, duration
	)
