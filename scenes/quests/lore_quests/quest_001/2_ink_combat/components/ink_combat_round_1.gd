# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var input_hints: HBoxContainer = %InputHints


func _ready() -> void:
	input_hints.visible = false


func _on_repel_powerup_collected() -> void:
	input_hints.visible = true
