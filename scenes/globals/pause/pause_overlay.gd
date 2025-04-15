# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if Pause.is_paused(Pause.System.GAME):
		visible = false
		Pause.unpause_system(Pause.System.GAME, self)
	else:
		visible = true
		Pause.pause_system(Pause.System.GAME, self)
