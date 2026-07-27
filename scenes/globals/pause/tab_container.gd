# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TabContainer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_tab"):
		current_tab = wrapi(current_tab + 1, 0, get_tab_count())
		accept_event()
	elif event.is_action_pressed("previous_tab"):
		current_tab = wrapi(current_tab - 1, 0, get_tab_count())
		accept_event()
