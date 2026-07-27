# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AudioStreamPlayer

var playback_position: float = 0.0
var _was_paused: bool = false

func _ready():

	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not playing:
		play()

func _process(_delta):

	var is_game_paused = get_tree().paused
	
	if is_game_paused != _was_paused:

		_was_paused = is_game_paused
		
		if is_game_paused:

			playback_position = get_playback_position()
			stop()
		else:

			play(playback_position)
