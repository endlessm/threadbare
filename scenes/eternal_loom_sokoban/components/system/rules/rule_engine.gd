# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@icon("uid://bydigjpyb14lv")
class_name RuleEngine
extends Node
## Top level manager of Input and Output for Sokoban-Style puzzles.
##
## Every turn the RuleEngine takes in a direction,
## sets all controllable pieces to move,
## applies each rule to the board,
## applies movement to the board,
## and then checks if all the goals have been reached.

signal goals_reached

const RULE_REPEAT_LIMIT := 99

@export var directional_input: DirectionalInput
@export var board: Board2D

## Every piece with this tag will attempt to move each turn.
@export var controllable_tag: StringName = "controllable"

## Every tag being used by pieces need to be set here to be recognized as tags.
@export var tags_legend: Array[StringName] = ["controllable"]

## When all goals are met, the RuleEngine will attempt to load this scene next.
@export_file("*.tscn") var scene_to_go_to: String

var rules: Array[Rule]
var goals: Array[Goal]

var first_state: BoardState
var undo_steps: Array[BoardState]


func _ready() -> void:
	directional_input.input = _directional_input

	for child in get_children():
		if child is Rule:
			rules.append(child)
		if child is Goal:
			goals.append(child)

	_setup_first_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		_undo()
	if event.is_action_pressed("reset"):
		_reset()


func _undo() -> void:
	if undo_steps.size() > 0:
		undo_steps[-1].apply()
		undo_steps.pop_back()


func _reset() -> void:
	undo_steps = []
	first_state.apply()


func _setup_first_state() -> void:
	if not board.is_node_ready():
		await board.ready

	# Pieces instanced using TileMapLayer need an extra frame
	await get_tree().process_frame

	first_state = BoardState.new()
	for piece in board.get_pieces():
		first_state.add_piece_state(PieceState.from_piece(piece))


func _directional_input(direction_2d: Vector2i) -> bool:
	if _take_turn(direction_2d):
		_check_goal()
		return true
	return false


func _take_turn(direction_2d: Vector2i) -> bool:
	var undo_state := BoardState.new()

	# collect all move attempts from player pieces
	for player in board.get_pieces(Board2D.Query.new().add_tag(controllable_tag)):
		player.set_vector(direction_2d)

	# run rules here
	for rule in rules:
		for i in RULE_REPEAT_LIMIT:
			var is_applied := rule.apply(board, self)
			if not is_applied:
				break

	# do movement here
	var total_checked_pieces: Array[Piece2D] = []

	var moving_pieces := board.get_pieces(
		Board2D.Query.new().add_direction(Piece2D.DIRECTION.NONE).set_is_exclusive(true)
	)

	# check each moving piece, if they run into other moving pieces, they all either fail or succeed
	for moving_piece in moving_pieces:
		if moving_piece in total_checked_pieces:
			continue

		var checked_pieces: Array[Piece2D] = []
		var result := piece_can_move(moving_piece, checked_pieces)

		for checked in checked_pieces:
			if result:
				undo_state.add_piece_state(PieceState.from_piece(checked))
				checked.apply_movement()

				# record diff & add undo state
			else:
				checked.cancel_movement()

		total_checked_pieces.append_array(checked_pieces)

	# run late rules here

	# commands are run here

	if not undo_state.is_empty():
		undo_steps.append(undo_state)
		return true
	return false


func _check_goal() -> void:
	var result := true
	for goal in goals:
		result = result and goal.is_all_completed(board, self)

	if result:
		goals_reached.emit()

		if scene_to_go_to:
			SceneSwitcher.change_to_file_with_transition(scene_to_go_to)


func piece_can_move(piece: Piece2D, checked_pieces: Array[Piece2D]) -> bool:
	# check for infinite loop
	if piece in checked_pieces:
		return false

	checked_pieces.append(piece)

	# if not moving
	if piece.direction == Piece2D.DIRECTION.NONE:
		return false

	# get all colliding tiles
	var collision_pieces := board.get_pieces_at(
		piece.get_new_grid_position(), Board2D.Query.new().add_layer(piece.layer)
	)

	# check if colliding with moving tiles
	for collision_piece in collision_pieces:
		# make sure you don't check yourself
		if piece == collision_piece:
			continue

		# if matching new positions, check if the other attempt can move recursively
		if piece.get_new_grid_position() == collision_piece.grid_position:
			return piece_can_move(collision_piece, checked_pieces)

	return true
