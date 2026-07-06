# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node


func _ready() -> void:
	var bgm := get_parent() as BackgroundMusic
	bgm.stream = MusicPlayer.background_music_player.stream
