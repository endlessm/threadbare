# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name MusicalRockXylophone
extends Node2D

signal note_played(note: String)

var _notes: Dictionary[String, MusicalRock]


func _ready() -> void:
	for node: Node in get_children():
		var rock: MusicalRock = node as MusicalRock
		if not rock:
			continue

		_notes[rock.note] = rock
		rock.note_played.connect(func() -> void: note_played.emit(rock.note))


func play_note(note: String) -> void:
	await _notes[note].play()


func stop_all_hints() -> void:
	for rock in _notes.values():
		rock.stop_hint()
