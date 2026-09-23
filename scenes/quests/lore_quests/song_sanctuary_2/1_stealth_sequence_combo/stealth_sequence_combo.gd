# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const FACT_NAME := "combo_puzzle_progress"

@onready var sequence_puzzle: SequencePuzzle = %SequencePuzzle
@onready var collectible_item: CollectibleItem = %CollectibleItem
@onready var background_music: BackgroundMusic = %BackgroundMusic


func _ready() -> void:
	if FACT_NAME in GameState.quest.facts:
		sequence_puzzle.set_progress(GameState.quest.facts[FACT_NAME])
		_update_music_clip(true)

	if sequence_puzzle.is_solved():
		collectible_item.revealed = true

	sequence_puzzle.progress_changed.connect(_update_music_clip)
	sequence_puzzle.step_solved.connect(_on_sequence_puzzle_step_solved)
	sequence_puzzle.solved.connect(_on_sequence_puzzle_solved)


func _on_sequence_puzzle_step_solved(step_index: int) -> void:
	GameState.quest.facts[FACT_NAME] = step_index


func _on_sequence_puzzle_solved() -> void:
	collectible_item.reveal()


func _update_music_clip(respawning: bool = false) -> void:
	var step_index := sequence_puzzle.get_progress()
	var stream := background_music.stream as AudioStreamInteractive
	var next_clip: StringName
	if respawning and step_index == 3:
		# Clip 3 ("LeadIn") is a lead-in to clip 4 ("FullLoop") to allow a
		# cymbal swell to bring in the loop. We don't want to switch to
		# LeadIn after respawning if FullLoop is already playing: this
		# sounds ugly because the full "band" drops out for a bar then comes
		# back in. So instead we trigger FullLoop in that case. If the Step3 ->
		# LeadIn transition had not run before the player was defeated, this
		# causes Step3 to switch to FullLoop directly, which doesn't sound
		# amazing but is worse than breaking the loop every time you are
		# defeated.
		#
		# I tried two other approaches:
		# - Tacking the transition onto the start of FullLoop then setting the
		#   loop offset. This is not supported on the web platform.
		# - Configuring the Step3 to FullLoop transition to use the LeadIn
		#   clip as a filler. This almost works, except that Godot adds a 1-beat
		#   fade-in at the start of FullLoop even though I configure "No Fade".
		#   I think this is another Godot bug... I left this configured in the
		#   resource, so one can hear it in the Step3 -> FullLoop edge case
		#   described above.
		next_clip = &"FullLoop"
	else:
		# This assumes that the clip indexes correspond to the puzzle progress with no offset.
		next_clip = stream.get_clip_name(step_index)
	MusicPlayer.play_stream(stream, next_clip)
