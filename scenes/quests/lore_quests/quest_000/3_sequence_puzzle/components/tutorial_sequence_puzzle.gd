# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var cinematic: Cinematic = %Cinematic
@onready var tutorial_npc: CharacterBody2D = %TutorialNPC
@onready var puzzle: SequencePuzzle = %SequencePuzzle


func _ready() -> void:
	if not GameState.intro_dialogue_shown:
		await cinematic.cinematic_finished

	tutorial_npc.walk_path()
