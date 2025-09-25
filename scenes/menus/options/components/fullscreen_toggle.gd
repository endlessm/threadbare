# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CheckButton


func _ready() -> void:
	# There are two instances of this toggle in the game: one on the title screen, and
	# another in the pause overlay. At most one is displayed at a time, so we can keep them in
	# synch by reading the setting each time each toggle is displayed.
	visibility_changed.connect(_refresh)
	_refresh()

	toggled.connect(_on_toggled)


func _refresh() -> void:
	set_pressed_no_signal(Settings.is_fullscreen())


func _on_toggled(toggled_on: bool) -> void:
	Settings.toggle_fullscreen(toggled_on)
