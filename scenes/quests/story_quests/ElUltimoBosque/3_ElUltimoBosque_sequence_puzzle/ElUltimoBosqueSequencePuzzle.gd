extends SequencePuzzle

signal step_solved(step_index: int)

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
	
	step_solved.emit(_current_step) ##señal cuando se complete un step
	
	_update_current_step()

	_clear_last_hint_object()

	if _current_step == steps.size():
		_debug("All sequences played")
		solved.emit()
	else:
		_debug("Next sequence: %s", [steps[_current_step]])
