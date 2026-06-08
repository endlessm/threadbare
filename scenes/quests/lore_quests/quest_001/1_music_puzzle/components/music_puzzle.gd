# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var background_music: BackgroundMusic = %BackgroundMusic
@onready var thread: CollectibleItem = %CollectibleItem


func _on_sequence_puzzle_step_solved(step_index: int) -> void:
	# This assumes that the clip indexes correspond to the puzzle indexes.
	var stream := background_music.stream as AudioStreamInteractive
	var next_clip := stream.get_clip_name(step_index + 1)
	MusicPlayer.switch_to_clip(next_clip)


func _on_sequence_puzzle_solved() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for tml: TileMapLayer in $TileMapLayers.get_children():
		tween.tween_property(tml, "modulate", Color.WHITE, 5.0)
