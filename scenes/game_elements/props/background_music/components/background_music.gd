# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

@export_tool_button("Play") var play_button: Callable = _play
@export_tool_button("Stop") var stop_button: Callable = _stop
@export_tool_button("Pause/Resume") var pause_resume_button: Callable = _pause_resume
@export var stream: AudioStream:
	set(new_value):
		stream = new_value
		update_configuration_warnings()

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer


func _get_configuration_warnings() -> PackedStringArray:
	if not stream:
		return ["Audio stream is not set, so there won't be background music!"]

	return []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_play()


func _play() -> void:
	if stream:
		audio_stream_player.stream = stream
		audio_stream_player.play()


func _stop() -> void:
	audio_stream_player.stop()


func _pause_resume() -> void:
	if audio_stream_player.is_playing():
		audio_stream_player.stream_paused = true
	else:
		audio_stream_player.stream_paused = false
