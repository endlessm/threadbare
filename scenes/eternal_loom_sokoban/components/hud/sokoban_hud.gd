# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends MarginContainer

@onready var skip_container: HBoxContainer = %SkipContainer


func _ready() -> void:
	skip_container.visible = false


func display_skip() -> void:
	skip_container.visible = true
