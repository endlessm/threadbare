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
@export var fires: Array[BonfireSign]

## If enabled, show messages in the console describing the player's progress (or not) in the puzzle
@export var debug: bool = false

var hint_timer: Timer = Timer.new()
var _last_hint_rock: MusicalRock = null
var _current_melody: int = 0
var _position: int = 0

var _is_demo: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		xylophone.note_played.connect(_on_note_played)

	hint_timer.one_shot = true
	hint_timer.wait_time = 6
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	add_child(hint_timer)

	_update_current_melody()

func _update_current_melody():
	for i in range(_current_melody, fires.size()):
		# We find the next fire that is not ignited, and that's the _current_melody
		if fires[i].is_ignited:
			_current_melody = i + 1
			_position = 0
		else:
			break


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
		_debug("Didn't match")
		_position = 0
		_debug("Matching again at start of melody...")
		xylophone.stop_all_hints()
		hint_timer.start()
		return

	_position += 1
	hint_timer.start()
	if _position != melody.length():
		_debug("Played %s, awaiting %s", [melody.left(_position), melody.right(-_position)])
		return

	_debug("Finished melody")
	fires[_current_melody].ignite()
	_update_current_melody()

	_clear_last_hint_rock()

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


func play_demo_melody_of_fire(fire: BonfireSign) -> void:
	await play_demo_melody(fires.find(fire))


func play_demo_melody(melody: int) -> void:
	for note in melodies[melody]:
		await play_demo_note(note)


func _on_hint_timer_timeout() -> void:
	if _current_melody >= melodies.size():
		return

	var melody: String = melodies[_current_melody]
	var expected_note := melody[_position]

	if xylophone._notes.has(expected_note):
		var rock = xylophone._notes[expected_note]
		if rock != _last_hint_rock:
			_clear_last_hint_rock()
			_last_hint_rock = rock

		if is_instance_valid(_last_hint_rock):
			_last_hint_rock.wobble_silently()

	hint_timer.start()


func _clear_last_hint_rock() -> void:
	if _last_hint_rock and is_instance_valid(_last_hint_rock):
		_last_hint_rock.stop_hint()
		_last_hint_rock = null


func stop_hints() -> void:
	hint_timer.stop()
	_clear_last_hint_rock()


func reset_hint_timer() -> void:
	hint_timer.stop()
	if _current_melody < melodies.size():
		hint_timer.start()
