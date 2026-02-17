# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ChampSequencePuzzle
extends SequencePuzzle

const CHECKPOINT_POS: Vector2 = Vector2(1400,180)
const RESPAWN_DELAY: float = 1.5
const ROCK_WIDTH: int = 3
const STARTING_POS: Vector2 = Vector2(350,350)

var first_seq_solve_index: int = 0
var kicked_object: SequencePuzzleObject
var objs: Array 
var offset: int = 0
var prev_pos: int = 0
var platforms: Array
var sequences: Array
var solve_progress: int = 0

@onready var camera: Camera2D = $"../Player/Camera2D"
@onready var long_rocks: Node2D = $"../../LongRocks"
@onready var objects: Node2D = $Objects
@onready var player: Player = $"../Player"
@onready var puzzle_steps: Node2D = $Steps

func _ready() -> void:
	camera.global_position = player.global_position
	sequences = puzzle_steps.get_children()
	platforms = Array(long_rocks.get_children())
	objs = Array(objects.get_children())
	if sequences.size() > 0:
		first_seq_solve_index = sequences[0].sequence.size() - 1
	super._ready()
	
## Function that handles kicking object edge cases, including the last object in the sequence or bad guesses resulting in flooding the rocks
func _on_kicked(object: SequencePuzzleObject) -> void:
	var second_seq_solve_index: int = 0
	# TODO: Make this dynamic for n number of sequences?
	if sequences.size() > 1:
		second_seq_solve_index = first_seq_solve_index + sequences[1].sequence.size()
	prev_pos = _position
	super._on_kicked(object)
	if _position == 0:
		var found_last: bool = false
		for seq in sequences:
			var seq_len: int = seq.sequence.size() - 1
			if seq.sequence[seq_len] == object:
				found_last = true
		prev_pos = 0 # TODO: Might not be necessary?
		# TODO: These are hard coded now until I understand order of step solve and kick
		if solve_progress == first_seq_solve_index and found_last:
			solve_progress = solve_progress + 1
			for i in range(ROCK_WIDTH * first_seq_solve_index, ROCK_WIDTH * (first_seq_solve_index + 1)):
				if objs[i] is ChampSequencePuzzleObject and objs[i] != object:
					objs[i].submerge()
			object.dry_off()
		elif solve_progress == second_seq_solve_index and found_last:
			for i in range(ROCK_WIDTH * second_seq_solve_index, ROCK_WIDTH * (second_seq_solve_index + 1)):
				if objs[i] is ChampSequencePuzzleObject and objs[i] != object:
					objs[i].submerge()
			object.dry_off()
		else:
			# Not the right object to kick
			for platform in platforms:
				if not platform.submerged:
					platform.toggle_water_level()
			if solve_progress > first_seq_solve_index:
				solve_progress = first_seq_solve_index
			else:
				solve_progress = 0
	elif _position > prev_pos:
		object.interact_area.disabled = true
		# Making progress towards solving sequence
		solve_progress = solve_progress + 1
		if platforms[solve_progress].submerged:
			platforms[solve_progress].toggle_water_level()
		# Only want sets of ROCK_WIDTH (3) centered around the position
		for i in range((ROCK_WIDTH * (_position - 1)) + offset, (ROCK_WIDTH * _position) + offset):
			if objs[i] is ChampSequencePuzzleObject and objs[i] != object:
				objs[i].submerge()
		object.dry_off()
	# Position > 0, but not correct spot
	else:
		# Reset everything
		reset_all()
		solve_progress = 0
		_position = 0

## Prohibits player from going back through first sequence
func _on_step_solved(step_index: int) -> void:
	if _current_step == 0:
		for i in range(ROCK_WIDTH * first_seq_solve_index, ROCK_WIDTH * (first_seq_solve_index + 1)):
			objs[i].interact_area.disabled = true
	offset = ROCK_WIDTH * (first_seq_solve_index + 1)
	
## Function to change player position to previous checkpoint based on puzzle solve progress (this version saves progress when moving player)
func _on_champ_long_rock_water_entered() -> void:
	player.mode = Player.Mode.DEFEATED
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if (_current_step == 1):
		var solve_length : int = first_seq_solve_index + 1
		if platforms[solve_length].submerged:
			platforms[solve_length].toggle_water_level()
		player.position = CHECKPOINT_POS
		# Restore all submerged platforms
		for i in range(solve_length + 1, platforms.size()):
			if not platforms[i].submerged:
				platforms[i].toggle_water_level()
		# Reset collisions so steps can't be skipped
		for i in range(offset, objs.size()):
			objs[i].collision.disabled = false
			if sequences[0].sequence.has(objs[i]) or sequences[1].sequence.has(objs[i]):
				objs[i].interact_area.disabled = false
		solve_progress = solve_length

	# Player is on first sequence
	else:
		player.position = STARTING_POS
		if platforms[0].submerged:
			platforms[0].toggle_water_level()
		# Restore all submerged platforms
		for i in range(1, platforms.size()):
			if not platforms[i].submerged and i != first_seq_solve_index + 1:
				platforms[i].toggle_water_level()
		if platforms[first_seq_solve_index + 1].submerged:
			platforms[first_seq_solve_index + 1].toggle_water_level()
		# Reset collisions so steps can't be skipped
		for i in range(0, objs.size()):
			objs[i].collision.disabled = false
			if sequences[0].sequence.has(objs[i]) or sequences[1].sequence.has(objs[i]):
				objs[i].interact_area.disabled = false
		solve_progress = 0 # redundant?
	player.mode = Player.Mode.COZY

## Overrides the parent function so we can continue to do logic after sequence ends
func _on_demonstrate_sequence(step: SequencePuzzleStep) -> void:
	await super._on_demonstrate_sequence(step)
	_on_hint_sign_hint_sequence_finished()

## Signal from hint sign to reset camera view and sequence
func _on_hint_sign_hint_sequence_finished() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	camera.global_position = player.global_position
	player._toggle_player_behavior(player.player_interaction, true)

## Function to rest all sequence objets after displaying via hint sequence
func reset_all() -> void:
	for platform in platforms:
		if not platform.submerged:
			platform.toggle_water_level()
	if platforms[0].submerged:
		platforms[0].toggle_water_level()
	if platforms[first_seq_solve_index + 1].submerged:
		platforms[first_seq_solve_index + 1].toggle_water_level()
		
	# TODO: Maybe a better way to do this, because of the way I manually change
	# sprite frames, I can't just wipe everything
	for obj in objs:
		if sequences[0].sequence.has(obj) or sequences[1].sequence.has(obj):
			obj.rock.play(obj._idle_animation)

## Function to move camera position so entire sequence is shown (for second sequence)
func _on_hint_sign_2_demonstrate_sequence() -> void:
	player._toggle_player_behavior(player.player_interaction, false)
	camera.global_position = $Objects/Middle8.global_position


func _on_hint_sign_1_demonstrate_sequence() -> void:
	player._toggle_player_behavior(player.player_interaction, false)
	camera.global_position = $Objects/Middle3.global_position
