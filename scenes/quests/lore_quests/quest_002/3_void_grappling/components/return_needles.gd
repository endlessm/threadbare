# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func appear() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
