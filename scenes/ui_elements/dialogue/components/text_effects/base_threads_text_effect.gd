# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
## Base class for the magical threads text effect
@abstract class_name BaseThreadsTextEffect
extends RichTextEffect

var text_color_1: Color
var text_color_2: Color

var speed: float = 4.0
var span: float = 2.0


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var time_var := sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5

	char_fx.color = text_color_1.lerp(text_color_2, time_var)
	char_fx.offset = Vector2(0, -time_var * 2)

	return true
