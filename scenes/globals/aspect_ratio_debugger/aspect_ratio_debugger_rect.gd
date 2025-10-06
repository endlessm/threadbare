# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
## A control that shows vertical or horizontal bars when the aspect ratio
## is too wide or too tall.
##
## The project sets the aspect ratio to expand, but there aren't minimum
## or maximum limits. This is a visual clue for dressing the scenes.

const BAR_COLOR := Color(Color.RED, 0.4)


func _draw() -> void:
	var aspect := size.aspect()

	# Too wide, add vertical bars:
	if aspect >= Settings.MAXIMUM_ASPECT_RATIO:
		var bar_width := (size.x - (size.y * Settings.MAXIMUM_ASPECT_RATIO)) / 2.0
		draw_rect(Rect2(0, 0, bar_width, size.y), BAR_COLOR)
		draw_rect(Rect2(size.x - bar_width, 0, bar_width, size.y), BAR_COLOR)
	# Too tall, add vertical bars:
	elif aspect < Settings.MINIMUM_ASPECT_RATIO:
		var bar_width := ((size.y * Settings.MINIMUM_ASPECT_RATIO) - size.x) / 2.0
		draw_rect(Rect2(0, 0, size.x, bar_width), BAR_COLOR)
		draw_rect(Rect2(0, size.y - bar_width, size.x, bar_width), BAR_COLOR)
