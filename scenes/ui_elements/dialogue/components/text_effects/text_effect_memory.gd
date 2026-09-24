# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MemoryTextEffect
extends BaseThreadsTextEffect

var bbcode := "Memory"


func _init() -> void:
	text_color_1 = Color("4a7d00ff")
	text_color_2 = Color("a0cf5bff")
