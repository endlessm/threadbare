# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VolumeSlider
extends HSlider

## Which bus this slider controls
@export var bus_name: String:
	set(new_value):
		bus_name = new_value
		_refresh()


func _ready() -> void:
	min_value = Settings.MIN_VOLUME
	_refresh()


func _on_visibility_changed() -> void:
	# There are two instances of each volume control in the game: one on the title screen, and
	# another in the pause overlay. At most one is displayed at a time, so we can keep them in
	# synch by reading the setting each time the slider is displayed.
	if visible:
		_refresh()


func _refresh() -> void:
	if bus_name:
		var new_value := Settings.get_volume(bus_name)
		set_value_no_signal(new_value)


func _on_value_changed(new_value: float) -> void:
	if bus_name:
		Settings.set_volume(bus_name, new_value)
