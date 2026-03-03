# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node
## Global music player
##
## This singleton node handles playing background music. It is controlled by a
## [BackgroundMusic] node in each scene, which specifies which stream to play in
## that scene.
##
## When switching to a new scene, this node determines whether the music has
## changed. If so, it fades out the old music (if any) before playing the new
## music.

## Time to fade out the previous music before playing a new stream. This should
## be kept in sync with the Transitions visual fade duration.
const FADE_DURATION_SECONDS := 1.0

# If true, the previous BackgroundMusic node has left the tree, and we are
# expecting a call to play_stream() from a BackgroundMusic in the new scene. If
# no such call arrives, we will fade out the current music anyway.
var _pending_new_stream: bool = false

var _tween: Tween

@onready var background_music_player: AudioStreamPlayer = %BackgroundMusicPlayer


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	if _pending_new_stream:
		# No background music in the new scene.
		background_music_player.stop()
		background_music_player.stream = null
		_pending_new_stream = false


## Called to indicate that the scene is about to change. If no corresponding
## call to [member play_stream] arrives before [signal SceneTree.scene_changed]
## is emitted, the current music will fade out.
func scene_about_to_change() -> void:
	_pending_new_stream = true


func _get_clip_index_by_name(stream: AudioStreamInteractive, clip_name: StringName) -> int:
	for index in stream.clip_count:
		if stream.get_clip_name(index) == clip_name:
			return index

	return -1


## Start playing [param stream], if it is not already playing, fading out any
## other stream that was playing before. If [param stream] is an [AudioStreamInteractive],
## and [param clip_name] is not empty, transition to the clip of that name.
func play_stream(stream: AudioStream, clip_name: StringName = &"") -> void:
	if clip_name and stream is not AudioStreamInteractive:
		push_warning("clip_name can only be used with AudioStreamInteractive")
		clip_name = &""

	if _tween:
		_tween.kill()
		_tween = null

	_pending_new_stream = false

	if background_music_player.stream:
		if background_music_player.stream == stream:
			if clip_name:
				# Start this transition now, not at the end of the visual fade: the transition
				# in the AudioStreamInteractive can be configured to match the visual fade if
				# desired.
				switch_to_clip(clip_name)
			return

		# Fade out previous music
		_tween = create_tween()
		_tween.tween_property(background_music_player, "volume_linear", 0.0, FADE_DURATION_SECONDS)
		await _tween.finished
		_tween = null
	elif not Engine.is_editor_hint() and Transitions.is_running():
		# When switching from a scene without music to a scene with music, still
		# wait for the visual fade to finish before starting the new music.
		await Transitions.finished

	background_music_player.volume_linear = 1.0
	background_music_player.stream = stream
	var orig_clip_index := -1
	if clip_name:
		var clip_index: int = _get_clip_index_by_name(stream, clip_name)
		if clip_index < 0:
			push_warning("Stream %s has no clip named %s" % [stream, clip_name])
		else:
			# We have to modify the AudioStreamInteractive resource to change
			# which clip it starts from. If we switched to the target clip, we
			# would hear the initial clip immediately transitioning (e.g. with a
			# fade) to the desired clip. Save the original value and change it
			# back right after starting playback, so that when running in the
			# editor the modified resource is not saved.
			orig_clip_index = stream.initial_clip
			stream.initial_clip = clip_index
	background_music_player.play()
	if orig_clip_index >= 0:
		stream.initial_clip = orig_clip_index


## If the currently-playing stream is an [AudioStreamInteractive], and music is
## playing, switch to [param clip_name].
func switch_to_clip(clip_name: StringName) -> void:
	if not background_music_player.is_playing():
		push_warning("Not currently playing")
		return

	if background_music_player.stream is not AudioStreamInteractive:
		push_warning("Switching clips is only supported with AudioStreamInteractive")
		return

	var playback := background_music_player.get_stream_playback() as AudioStreamPlaybackInteractive
	var current: StringName = background_music_player.stream.get_clip_name(
		playback.get_current_clip_index()
	)
	if current != clip_name:
		playback.switch_to_clip_by_name(clip_name)
