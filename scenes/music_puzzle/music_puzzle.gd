extends Node

@export var xylophone: MusicalRockXylophone

## Melodies expressed with the letters ABCDEFG.
@export var melodies: Array[String]

## A fire corresponding to each melody, ignited when the correct melody is played (in order).
@export var fires: Array[Bonfire]

var _current_melody := 0
var _position := 0

func _ready() -> void:
	xylophone.note_played.connect(_on_note_played)
	

func _on_note_played(note: String) -> void:
	if _current_melody >= melodies.size():
		return

	var melody := melodies[_current_melody]
	if melody[_position] == note:
		_position += 1
		if _position == melody.length():
			print("Finished melody ", _current_melody, ": ", melody)
			fires[_current_melody].ignite()
			_current_melody += 1
			_position = 0
			
			if _current_melody == melodies.size():
				print("all done")
			else:
				print("next please")
		else:
			print("Played melody ", _current_melody, " up to ", melody.left(_position))
			pass # Waiting for more notes
	else:
		print("bzzt")
		_position = 0
