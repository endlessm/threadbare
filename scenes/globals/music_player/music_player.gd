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


## Start playing [param stream], if it is not already playing, fading out any
## other stream that was playing before.
func play_stream(stream: AudioStream) -> void:
	if _tween:
		_tween.kill()
		_tween = null

	_pending_new_stream = false

	if background_music_player.stream:
		if background_music_player.stream == stream:
			# No change needed
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
	background_music_player.play()


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
	playback.switch_to_clip_by_name(clip_name)
