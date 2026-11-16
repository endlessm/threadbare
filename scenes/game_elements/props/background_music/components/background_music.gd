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

@onready var audio_stream_player: AudioStreamPlayer = MusicPlayer.background_music_player


func _get_configuration_warnings() -> PackedStringArray:
	if not stream:
		return ["Audio stream is not set, so there won't be background music!"]

	return []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if stream:
		_fade_in()
		_play()
	else:
		_stop()

	Transitions.started.connect(self._fade_out)


func _play() -> void:
	if audio_stream_player.stream == stream and audio_stream_player.playing:
		return

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


func _fade_in() -> void:
	create_tween().tween_property(audio_stream_player, "volume_db", linear_to_db(1.0), 1.0)


func _fade_out() -> void:
	# If we use linear_to_db(0.0) as final value, the audio stream player
	# is muted instantly because it goes from 0.0db to -infdb.
	create_tween().tween_property(audio_stream_player, "volume_db", linear_to_db(0.00001), 1.0)


func _exit_tree() -> void:
	## Without this, if you click the Play button and then close the scene
	## in the editor, the music will keep playing.
	if Engine.is_editor_hint():
		_stop()
