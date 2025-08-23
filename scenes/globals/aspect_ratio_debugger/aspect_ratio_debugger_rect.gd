# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ColorRect
## A ColorRect that shows vertical or horizontal bars when the aspect ratio
## is too wide or too tall.
##
## The project sets the aspect ratio to expand, but there aren't minimum
## or maximum limits. This is a visual clue for dressing the scenes.


func _draw():
	var aspect = get_size().aspect()
	# Too wide, add vertical bars:
	if aspect >= Settings.MAXIMUM_ASPECT_RATIO:
		var bar_width := (get_size().x - (get_size().y * Settings.MAXIMUM_ASPECT_RATIO)) / 2.0
		draw_rect(Rect2(0, 0, bar_width, get_size().y), Color(Color.RED, 0.4))
		draw_rect(
			Rect2(get_size().x - bar_width, 0, bar_width, get_size().y), Color(Color.RED, 0.4)
		)
	# Too tall, add vertical bars:
	elif aspect < Settings.MINIMUM_ASPECT_RATIO:
		var bar_width := ((get_size().y * Settings.MINIMUM_ASPECT_RATIO) - get_size().x) / 2.0
		draw_rect(Rect2(0, 0, get_size().x, bar_width), Color(Color.RED, 0.4))
		draw_rect(
			Rect2(0, get_size().y - bar_width, get_size().x, bar_width), Color(Color.RED, 0.4)
		)
