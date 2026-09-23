# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MemoryTextEffect
extends RichTextEffect

var bbcode := "Memory"

var text_color := Color("#4A7D00")
var text_markup := Color("a0cf5bff")

var speed: float = 4.0
var span: float = 2.0


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var time_var := sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5

	char_fx.color = text_color.lerp(text_markup, time_var)
	char_fx.offset = Vector2(0, -time_var * 2)

	return true
