# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const FACT_NAME := "combo_puzzle_progress"

@onready var sequence_puzzle: SequencePuzzle = %SequencePuzzle
@onready var collectible_item: CollectibleItem = %CollectibleItem


func _ready() -> void:
	if FACT_NAME in GameState.quest.facts:
		sequence_puzzle.set_progress(GameState.quest.facts[FACT_NAME])

	if sequence_puzzle.is_solved():
		collectible_item.revealed = true

	sequence_puzzle.step_solved.connect(_on_sequence_puzzle_step_solved)
	sequence_puzzle.solved.connect(_on_sequence_puzzle_solved)


func _on_sequence_puzzle_step_solved(step_index: int) -> void:
	GameState.quest.facts[FACT_NAME] = step_index


func _on_sequence_puzzle_solved() -> void:
	collectible_item.reveal()
