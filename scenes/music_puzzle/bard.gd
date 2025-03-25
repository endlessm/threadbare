## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var puzzle: MusicPuzzle


func play(note: String) -> void:
	await puzzle.xylophone.play_note(note)
