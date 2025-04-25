# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var puzzle: MusicPuzzle

var first_conversation: bool = true
var hint_levels: Dictionary = {}


func _ready() -> void:
	super._ready()
	for i in range(puzzle.melodies.size()):
		if not hint_levels.has(i):
			hint_levels[i] = 0


func play(note: String) -> void:
	await puzzle.play_demo_note(note)


func advance_hint_level() -> void:
	var progress := puzzle.get_progress()
	hint_levels[progress] = hint_levels.get(progress, 0) + 1


func get_limited_hint_level() -> int:
	var progress = puzzle.get_progress()
	var hint_level = hint_levels.get(progress, 0)
	var max_hint_level = 2
	return hint_level % (max_hint_level + 1)
