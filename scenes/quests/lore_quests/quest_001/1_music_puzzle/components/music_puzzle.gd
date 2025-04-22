# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name MusicPuzzle
extends Node2D

signal solved

@export var xylophone: MusicalRockXylophone

## Melodies expressed with the letters ABCDEFG.
@export var melodies: Array[String]

## A fire corresponding to each melody, ignited when the correct melody is played (in order).
@export var fires: Array[Bonfire]

## If enabled, show messages in the console describing the player's progress (or not) in the puzzle
@export var debug: bool = false

var _current_melody: int = 0
var _position: int = 0

var _is_demo: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		xylophone.note_played.connect(_on_note_played)


func _debug(fmt: String, args: Array = []) -> void:
	if debug:
		print((fmt % args) if args else fmt)


func _on_note_played(note: String) -> void:
	if _is_demo or _current_melody >= melodies.size():
		return

	var melody: String = melodies[_current_melody]
	_debug(
		"Current melody %s position %d expecting %s, received %s",
		[melody, _position, melody[_position], note],
	)
	if melody[_position] != note:
		if _position == 0:
			_debug("Didn't match")
			return

		_debug("Matching again at start of melody...")
		_position = 0

	if melody[_position] != note:
		_debug("Didn't match")
		return

	_position += 1
	if _position != melody.length():
		_debug("Played %s, awaiting %s", [melody.left(_position), melody.right(-_position)])
		return

	_debug("Finished melody")
	fires[_current_melody].ignite()
	_current_melody += 1
	_position = 0

	if _current_melody == melodies.size():
		_debug("All melodies played")
		solved.emit()
	else:
		_debug("Next melody: %s", [melodies[_current_melody]])


func _get_configuration_warnings() -> PackedStringArray:
	if melodies.size() != fires.size():
		var fmt: String = """
			There should be one fire for each melody, \
			but currently there are %d melodies and %d fires.
		"""
		return [fmt.strip_edges() % [melodies.size(), fires.size()]]

	return []


func get_progress() -> int:
	return _current_melody


func is_solved() -> bool:
	return _current_melody == melodies.size()


func play_demo_note(note: String) -> void:
	_is_demo = true
	await xylophone.play_note(note)
	_is_demo = false


func play_demo_melody_of_fire(fire: Bonfire) -> void:
	await play_demo_melody(fires.find(fire))


func play_demo_melody(melody: int) -> void:
	for note in melodies[melody]:
		await play_demo_note(note)
