# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var background_music: BackgroundMusic = %BackgroundMusic
@onready var thread: CollectibleItem = %CollectibleItem
@onready var sequence_puzzle: SequencePuzzle = %SequencePuzzle


func _ready() -> void:
	# Restore from saved state:
	if "music_puzzle_progress" in GameState.quest.facts:
		sequence_puzzle.set_progress(GameState.quest.facts.music_puzzle_progress)


func _change_music(step_index: int) -> void:
	# This assumes that the clip indexes correspond to the puzzle indexes.
	var stream := background_music.stream as AudioStreamInteractive
	var next_clip := stream.get_clip_name(step_index + 1)
	MusicPlayer.switch_to_clip(next_clip)


func _on_sequence_puzzle_step_solved(step_index: int) -> void:
	# Persist the state:
	GameState.quest.facts.music_puzzle_progress = step_index

	_change_music(step_index)


func _on_sequence_puzzle_progress_changed() -> void:
	_change_music(sequence_puzzle.get_progress())
