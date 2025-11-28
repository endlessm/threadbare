# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VaseDestructionTracker
extends Node2D

## Name of the group to monitor.
@export var target_group_name: String = "Vases"

## Time to wait before starting the transition (allows seeing the last breakage).
@export var pre_fade_delay: float = 1.5

var total_targets: int = 0
var destroyed_count: int = 0
var is_game_over: bool = false
var required_fills_to_win: int = 1  # Default value, will be updated from FillGameLogic


func _ready() -> void:
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame

	# Try to find the FillGameLogic node to sync the win condition
	var fill_logic: FillGameLogic = _find_fill_game_logic()
	if fill_logic:
		required_fills_to_win = fill_logic.barrels_to_win
		print(
			(
				"VaseDestructionTracker: Synced with FillGameLogic. Needed to win: %d"
				% required_fills_to_win
			)
		)
	else:
		push_warning(
			"VaseDestructionTracker: FillGameLogic node not found. Using default win condition: 1"
		)

	# Explicitly type the array as Array[Node] to fix the iterator warning
	var targets: Array[Node] = get_tree().get_nodes_in_group(target_group_name)
	total_targets = targets.size()

	print(
		(
			"VaseDestructionTracker started. Watching %d objects in group '%s'."
			% [total_targets, target_group_name]
		)
	)

	if total_targets == 0:
		push_warning(
			"VaseDestructionTracker: Group '%s' is empty or does not exist." % target_group_name
		)
		return

	for target in targets:
		if target.has_signal("vase_destroyed"):
			target.vase_destroyed.connect(_on_target_destroyed)
		else:
			push_error(
				(
					"Object %s in group %s is missing 'vase_destroyed' signal."
					% [target.name, target_group_name]
				)
			)


func _on_target_destroyed(_target_ref: Node) -> void:
	if is_game_over:
		return

	destroyed_count += 1
	check_loss_condition()


func check_loss_condition() -> void:
	# Dead-end check: Do we still have enough vases to win?
	var remaining_targets: int = total_targets - destroyed_count

	if remaining_targets < required_fills_to_win:
		trigger_game_over()


func trigger_game_over() -> void:
	is_game_over = true
	print("GAME OVER - Not enough targets left to win. Restarting...")

	# Wait to let the player see the breakage
	await get_tree().create_timer(pre_fade_delay).timeout

	# Use the project's transition system (SceneSwitcher)
	var current_scene_path: String = get_tree().current_scene.scene_file_path

	# Use default wipe transitions similar to Teleporter
	SceneSwitcher.change_to_file_with_transition.call_deferred(
		current_scene_path,
		^"",
		Transition.Effect.LEFT_TO_RIGHT_WIPE,
		Transition.Effect.RIGHT_TO_LEFT_WIPE
	)


# Helper function to find the logic node in the scene
func _find_fill_game_logic() -> FillGameLogic:
	var root: Node = get_tree().current_scene
	for child in root.get_children():
		if child is FillGameLogic:
			return child

	return null
