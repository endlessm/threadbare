# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name LabeledInputHint
extends Control

## The text shown to the user for this hint.
var text: String:
	get = get_text,
	set = set_text

@onready var label: Label = %Label


func get_text() -> String:
	return label.text


func set_text(new_value: String) -> void:
	label.text = new_value
