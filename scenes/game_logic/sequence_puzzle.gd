# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SequencePuzzle
extends Node2D
signal solved
## The order in which the player must interact with objects to solve each step of the puzzle
@export var steps: Array[SequencePuzzleStep]
## If enabled, the [SequencePuzzleHintSign] for the current step of the puzzle
## will be interactive, allowing the player to interact with the sign to see a
## demo of the corresponding sequence. If false, the signs are only interactive
## once the player has solved the corresponding step, which makes the puzzle
## harder!
@export var interactive_hints: bool = true
## If enabled, show messages in the console describing the player's progress (or not) in the puzzle
@export var debug: bool = false

var _objects: Array[SequencePuzzleObject]
var _last_hint_object: SequencePuzzleObject = null
var _current_step: int = 0
var _position: int = 0

func _ready() -> void:
	_find_objects()

	for step: SequencePuzzleStep in steps:
		step.hint_sign.demonstrate_sequence.connect(_on_demonstrate_sequence.bind(step))
	_update_current_step()

func _find_objects() -> void:
	_objects.clear()
	for o: Node in get_tree().get_nodes_in_group(&"sequence_object"):
		if self.is_ancestor_of(o) and o is SequencePuzzleObject:
			var object := o as SequencePuzzleObject
			_objects.append(object)
			object.kicked.connect(_on_kicked.bind(object))

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
	
func _on_kicked(object: SequencePuzzleObject) -> void:
	if _current_step >= steps.size():
		return
	var step := steps[_current_step]
	var sequence := step.sequence
	_debug(
		"Current sequence %s position %d expecting %s, received %s",
		[sequence, _position, sequence[_position], object],
	)
	if _position != 0 and sequence[_position] != object:
		_debug("Didn't match")
		_position = 0
		_debug("Matching again at start of sequence...")

	if sequence[_position] != object:
		_debug("Didn't match")
		for r: SequencePuzzleObject in _objects:
			r.stop_hint()
		return
	_position += 1
	
	if _position != sequence.size():
		_debug("Played %s, awaiting %s", [sequence.slice(0, _position), sequence.slice(_position)])
		return
	_debug("Finished sequnce")
	step.hint_sign.set_solved()
	_update_current_step()
	_clear_last_hint_object()
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
	for object in step.sequence:
		await object.play()
	step.hint_sign.demonstration_finished()
	
func _clear_last_hint_object() -> void:
	if _last_hint_object and is_instance_valid(_last_hint_object):
		_last_hint_object.stop_hint()
		_last_hint_object = null

func stop_hints() -> void:
	_clear_last_hint_object()
	
