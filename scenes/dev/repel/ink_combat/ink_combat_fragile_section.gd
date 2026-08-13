# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## This is a simplification of vase_destruction_tracker.gd [VaseDestructionTracker]
extends Node2D

## Reference to the logic node to know the win condition.
@export var fill_game_logic: FillGameLogic

## Time to wait before triggering defeat (allows seeing the last breakage).
@export var pre_fade_delay: float = 1.5

var total_targets: int = 0
var destroyed_count: int = 0

var _player: Player


func setup() -> void:
	fill_game_logic.barrels_to_win = 1

	_player = get_tree().get_first_node_in_group("player")

	var targets: Array[Node] = get_tree().get_nodes_in_group("filling_barrels")
	total_targets = targets.size()

	for target in targets:
		if target.has_signal("barrel_destroyed"):
			target.barrel_destroyed.connect(_on_target_destroyed)


func _on_target_destroyed(_target_ref: Node) -> void:
	# Check if player is already defeated to avoid multiple triggers
	if _player and _player.mode == Player.Mode.DEFEATED:
		return

	destroyed_count += 1
	check_loss_condition()


func check_loss_condition() -> void:
	# Dead-end check: Do we still have enough vases to win?
	var remaining_targets: int = total_targets - destroyed_count

	if remaining_targets < fill_game_logic.barrels_to_win:
		trigger_game_over()


func trigger_game_over() -> void:
	# Wait to let the player see the breakage
	await get_tree().create_timer(pre_fade_delay).timeout

	if _player:
		_player.defeat()
