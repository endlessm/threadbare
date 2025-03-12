class_name MusicalRockXylophone
extends Node2D

signal note_played(note: String)

func _ready() -> void:
	for node in get_children():
		var rock := (node as MusicalRock)
		if not rock:
			continue

		rock.note_played.connect(func (): note_played.emit(rock.note))
