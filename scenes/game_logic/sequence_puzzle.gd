# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SequencePuzzle
extends Node2D

## Emitted when the entire puzzle is solved
signal solved

## Emitted when an individual step of the puzzle is completed.
## [param step_index] is the index of the step that was just completed.
## This allows level designers to trigger events when specific steps are solved,
## beyond just the solved animation on the hint sign.
signal step_solved(step_index: int)

## The order in which the player must interact with objects to solve each step of the puzzle.
## If this is empty, [SequencePuzzleStep] nodes that are children (or grandchildren, etc.) of
## this node will be used, in depth-first order.
##
## @deprecated: Don't set this property directly: rely on the SequencePuzzleStep nodes being found
##              automatically.
@export var steps: Array[SequencePuzzleStep]

## If enabled, the [SequencePuzzleHintSign] for the current step of the puzzle
## will be interactive, allowing the player to interact with the sign to see a
## demo of the corresponding sequence. If false, the signs are only interactive
## once the player has solved the corresponding step, which makes the puzzle
## harder!
@export var interactive_hints: bool = true

## If enabled, show messages in the console describing the player's progress (or not) in the puzzle
@export var debug: bool = false

var hint_levels: Dictionary = {}

var _objects: Array[SequencePuzzleObject]

var _current_step: int = 0
var _position: int = 0


func _find_steps(node: Node) -> void:
	if node is SequencePuzzleStep:
		steps.append(node)
	for child in node.get_children():
		_find_steps(child)


func _ready() -> void:
	_find_objects()

	# If the steps array is empty, find all steps that are within this node
	if steps.is_empty():
		_find_steps(self)

	for step: SequencePuzzleStep in steps:
		step.hint_sign.demonstrate_sequence.connect(_on_demonstrate_sequence.bind(step))

	_update_current_step()

	for i in range(steps.size()):
		if not hint_levels.has(i):
			hint_levels[i] = 0


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
		return

	_position += 1
	if _position != sequence.size():
		_debug("Played %s, awaiting %s", [sequence.slice(0, _position), sequence.slice(_position)])
		return

	_debug("Finished sequence")
	step.hint_sign.set_solved()

	# Emit step_solved signal to allow level designers to react to individual step completion
	step_solved.emit(_current_step)
	_debug("Step %d solved", [_current_step])

	_update_current_step()

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
