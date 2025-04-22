# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var puzzle: MusicPuzzle

var first_conversation: bool = true


func play(note: String) -> void:
	await puzzle.play_demo_note(note)
