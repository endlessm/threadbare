# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BackgroundMusic
extends Node
## Specify the background music to play in a scene.
##
## This controls the singleton MusicPlayer node, which outlives every scene, so
## that music can keep playing between scenes.
## [br][br]
## If [member stream] is an [AudioStreamInteractive], you can control the clip
## to play at different points in the scene using [member clip], [method
## switch_to_clip], and [ClipSwitcher] child nodes.
## [br][br]
## There should be at most one BackgroundMusic component in a scene.

@export_tool_button("Play") var play_button: Callable = play
@export_tool_button("Stop") var stop_button: Callable = stop

## The music stream to play in this scene.
## [br][br]
## This should generally be configured to loop. For a simple audio file such as
## an [AudioStreamOggVorbis], configure it to loop in the Import panel. For an
## [AudioStreamPlaylist], you can set the [member AudioStreamPlaylist.loop]
## property. For an [AudioStreamInteractive], with great power comes great
## responsibility.
@export var stream: AudioStream:
	set(new_value):
		stream = new_value
		update_configuration_warnings()
		notify_property_list_changed()

## If [member stream] is an [AudioStreamInteractive], switch to the named clip
## (rather than [member stream]'s [member AudioStreamInteractive.initial_clip])
## when entering (or restarting) this scene.
## [br][br]
## If not set, the behaviour depends on what was playing in the previous scene.
## If a different stream was playing, [member stream]'s
## [member AudioStreamInteractive.initial_clip] will play. If [member stream]
## was already playing, whatever clip it happened to be playing will continue.
@export var clip: StringName:
	set(new_value):
		clip = new_value
		update_configuration_warnings()


func _get_clip_names() -> Array[String]:
	if stream is not AudioStreamInteractive:
		return []

	var names: Array[String] = [""]
	for i: int in stream.clip_count:
		names.append(stream.get_clip_name(i))
	return names


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"clip":
			if stream is AudioStreamInteractive:
				property.type = TYPE_STRING
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(_get_clip_names())
			else:
				# Hide clip property when it cannot be used
				property.usage = PROPERTY_USAGE_NONE


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not stream:
		warnings.append("Audio stream is not set, so there won't be background music!")
	elif stream is AudioStreamInteractive and clip and clip not in _get_clip_names():
		warnings.append("Clip '{0}' does not exist in the audio stream.".format(clip))

	return warnings


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
	MusicPlayer.play_stream(stream, clip)


## Stop playing background music.
func stop() -> void:
	MusicPlayer.play_stream(null)


## If [member stream] is an [AudioStreamInteractive], and is playing,
## switch to [param clip_name].
func switch_to_clip(clip_name: StringName) -> void:
	# TODO: remove this wrapper?
	MusicPlayer.switch_to_clip(clip_name)
