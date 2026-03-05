# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends HSlider


func _ready() -> void:
	value = Engine.time_scale
	value_changed.connect(_on_value_changed)


func _on_value_changed(new_value: float) -> void:
	Engine.time_scale = new_value
