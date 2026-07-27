# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VaseDestructionTracker
extends Node2D

## Name of the group to monitor.
@export var target_group_name: String = "Vases"

## Reference to the logic node to know the win condition.
@export var fill_game_logic: FillGameLogic

## Time to wait before triggering defeat (allows seeing the last breakage).
@export var pre_fade_delay: float = 1.5

var total_targets: int = 0
var destroyed_count: int = 0
var required_fills_to_win: int = 1  # Default value, updated from fill_game_logic

var _player: Player


func _ready() -> void:
	# 1. Sync with the explicit FillGameLogic node
	if fill_game_logic:
		required_fills_to_win = fill_game_logic.barrels_to_win
	else:
		# Split string to satisfy gdlint max-line-length (100)
		push_warning(
			(
				"VaseDestructionTracker: 'fill_game_logic' is not assigned. "
				+ "Using default win condition: 1"
			)
		)

	# 2. Find the Player to handle defeat state
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as Player
	else:
		push_error("VaseDestructionTracker: Player node not found in group 'player'.")

	# 3. Setup Targets
	# Explicitly type the array as Array[Node] to fix the iterator warning
	var targets: Array[Node] = get_tree().get_nodes_in_group(target_group_name)
	total_targets = targets.size()

	if total_targets == 0:
		push_warning(
			"VaseDestructionTracker: Group '%s' is empty or does not exist." % target_group_name
		)
		return

	for target in targets:
		if target.has_signal("barrel_destroyed"):
			target.barrel_destroyed.connect(_on_target_destroyed)
		else:
			push_error(
				(
					"Object %s in group %s is missing 'barrel_destroyed' signal."
					% [target.name, target_group_name]
				)
			)


func _on_target_destroyed(_target_ref: Node) -> void:
	# Check if player is already defeated to avoid multiple triggers
	if _player and _player.mode == Player.Mode.DEFEATED:
		return

	destroyed_count += 1
	check_loss_condition()


func check_loss_condition() -> void:
	# Dead-end check: Do we still have enough vases to win?
	var remaining_targets: int = total_targets - destroyed_count

	if remaining_targets < required_fills_to_win:
		trigger_game_over()


func trigger_game_over() -> void:
	# Wait to let the player see the breakage
	await get_tree().create_timer(pre_fade_delay).timeout

	if _player:
		_player.defeat()
