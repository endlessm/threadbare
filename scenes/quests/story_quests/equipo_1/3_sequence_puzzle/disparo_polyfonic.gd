# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AudioStreamPlayer2D
@export var sonido:AudioStreamPlayer2D

func play_audio()->void:
	if not playing:
		play()
	var playback = get_stream_playback()
	playback.play_stream(sonido.stream)
	
	
