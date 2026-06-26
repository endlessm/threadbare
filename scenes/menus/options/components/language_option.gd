# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends HBoxContainer

@onready var _english_button: Button = %EnglishButton
@onready var _spanish_button: Button = %SpanishButton
@onready var _french_button: Button = %FrenchButton


func _ready() -> void:
	# There are two instances of this option in the game: one on the title screen, and
	# another in the pause overlay. At most one is displayed at a time, so we can keep them in
	# synch by reading the setting each time each option is displayed.
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var current_locale := Settings.get_locale()
	_english_button.set_pressed_no_signal(current_locale == "en")
	_spanish_button.set_pressed_no_signal(current_locale == "es")
	_french_button.set_pressed_no_signal(current_locale == "fr")


func _on_button_pressed(language_code: String) -> void:
	Settings.set_locale(language_code)
	_refresh()
