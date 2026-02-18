# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BackgroundMusic
extends Node
## Specify the background music to play in a scene.
##
## This controls the singleton MusicPlayer node, which outlives every scene, so
## that music can keep playing between scenes.
##
## There should be at most one BackgroundMusic component in a scene.

@export_tool_button("Play") var play_button: Callable = play
@export_tool_button("Stop") var stop_button: Callable = stop

@export var stream: AudioStream:
	set(new_value):
		stream = new_value
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	if not stream:
		return ["Audio stream is not set, so there won't be background music!"]

	return []


func _ready() -> void:
	if not Engine.is_editor_hint():
		play()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		stop()
	else:
		MusicPlayer.scene_about_to_change()


## Start playing [member stream], if it is not already playing. Does nothing if
## [member stream] is already playing.
func play() -> void:
	MusicPlayer.play_stream(stream)


## Stop playing background music.
func stop() -> void:
	MusicPlayer.play_stream(null)


## If [member stream] is an [AudioStreamInteractive], and is playing,
## switch to [param clip_name].
func switch_to_clip(clip_name: StringName) -> void:
	MusicPlayer.switch_to_clip(clip_name)
