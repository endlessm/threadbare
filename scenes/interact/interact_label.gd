# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InteractLabel
extends PanelContainer

@export var label_text: String:
	set = _set_label_text

@onready var label: Label = %Label


func _set_label_text(new_text: String) -> void:
	label_text = new_text
	if not is_node_ready():
		return
	label.text = tr(new_text)


func _ready() -> void:
	_set_label_text(label_text)
