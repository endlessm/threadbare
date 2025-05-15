# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name MusicPuzzle
extends Node2D

signal solved

## The order in which the player must interact with rocks to solve each step of the puzzle
@export var steps: Array[SequencePuzzleStep]

## If enabled, the [SequencePuzzleHintSign] for the current step of the puzzle
## will be interactive, allowing the player to interact with the sign to see a
## demo of the corresponding sequence. If false, the signs are only interactive
## once the player has solved the corresponding step, which makes the puzzle
## harder!
@export var interactive_hints: bool = true

## If enabled, show messages in the console describing the player's progress (or not) in the puzzle
@export var debug: bool = false

@export var wobble_hint_time: float = 10.0
@export var wobble_hint_min_level: int = 2

var hint_timer: Timer = Timer.new()

var hint_levels: Dictionary = {}

var _rocks: Array[MusicalRock]

var _last_hint_rock: MusicalRock = null
var _current_step: int = 0
var _position: int = 0


func _ready() -> void:
	_find_rocks()

	hint_timer.one_shot = true
	hint_timer.wait_time = wobble_hint_time
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	add_child(hint_timer)

	for step: SequencePuzzleStep in steps:
		step.hint_sign.demonstrate_sequence.connect(_on_demonstrate_sequence.bind(step))

	_update_current_step()

	for i in range(steps.size()):
		if not hint_levels.has(i):
			hint_levels[i] = 0


func _find_rocks() -> void:
	_rocks.clear()

	for object: Node in get_tree().get_nodes_in_group(&"sequence_object"):
		if self.is_ancestor_of(object) and object is MusicalRock:
			var rock := object as MusicalRock
			_rocks.append(rock)
			rock.note_played.connect(_on_note_played.bind(rock))


func _update_current_step() -> void:
	for i in range(_current_step, steps.size()):
		# We find the next fire that is not solved, and that's the _current_step
		if steps[i].hint_sign.is_solved:
			_current_step = i + 1
			_position = 0
		else:
			break

	if interactive_hints and _current_step < steps.size():
		steps[_current_step].hint_sign.interactive_hint = true


func _debug(fmt: String, args: Array = []) -> void:
	if debug:
		print((fmt % args) if args else fmt)


func _on_note_played(rock: MusicalRock) -> void:
	if _current_step >= steps.size():
		return

	var step := steps[_current_step]
	var sequence := step.sequence
	_debug(
		"Current sequence %s position %d expecting %s, received %s",
		[sequence, _position, sequence[_position], rock],
	)
	if _position != 0 and sequence[_position] != rock:
		_debug("Didn't match")
		_position = 0
		_debug("Matching again at start of sequence...")

	if sequence[_position] != rock:
		_debug("Didn't match")
		for r: MusicalRock in _rocks:
			r.stop_hint()
		if hint_levels.get(get_progress(), 0) >= wobble_hint_min_level:
			hint_timer.start()
		return

	_position += 1
	hint_timer.start()
	if _position != sequence.size():
		_debug("Played %s, awaiting %s", [sequence.slice(0, _position), sequence.slice(_position)])
		return

	_debug("Finished sequnce")
	step.hint_sign.set_solved()
	_update_current_step()

	_clear_last_hint_rock()

	if _current_step == steps.size():
		_debug("All sequences played")
		solved.emit()
	else:
		_debug("Next sequence: %s", [steps[_current_step]])


func get_progress() -> int:
	return _current_step


func is_solved() -> bool:
	return _current_step == steps.size()


func _on_demonstrate_sequence(step: SequencePuzzleStep) -> void:
	for rock in step.sequence:
		await rock.play()
	step.hint_sign.demonstration_finished()


func _on_hint_timer_timeout() -> void:
	if _current_step >= steps.size():
		return

	var sequence := steps[_current_step].sequence
	var rock := sequence[_position]
	if rock:
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
	if _current_step < steps.size():
		hint_timer.start()
