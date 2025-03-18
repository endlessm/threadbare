class_name MusicalRockXylophone
extends Node2D

signal note_played(note: String)

var _notes: Dictionary[String, MusicalRock]


func _ready() -> void:
	for node in get_children():
		var rock := node as MusicalRock
		if not rock:
			continue

		_notes[rock.note] = rock
		rock.note_played.connect(func(): note_played.emit(rock.note))


func play_note(note: String) -> void:
	await _notes[note].play()
