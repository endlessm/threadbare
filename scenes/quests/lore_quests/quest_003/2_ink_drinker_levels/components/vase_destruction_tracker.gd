# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VaseDestructionTracker
extends Node2D

## Name of the group to monitor. If all nodes in this group are destroyed, Game Over triggers.
@export var target_group_name: String = "Vases"
## Time to wait before starting the transition (allows seeing the last breakage).
@export var pre_fade_delay: float = 1.5

var total_targets: int = 0
var destroyed_count: int = 0
var is_game_over: bool = false


func _ready() -> void:
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame

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
	# print("Object destroyed. Progress: %d/%d" % [destroyed_count, total_targets])
	check_loss_condition()


func check_loss_condition() -> void:
	if destroyed_count >= total_targets:
		trigger_game_over()


func trigger_game_over() -> void:
	is_game_over = true
	print("GAME OVER - All targets in group '%s' destroyed. Restarting..." % target_group_name)

	await get_tree().create_timer(pre_fade_delay).timeout

	var current_scene_path: String = get_tree().current_scene.scene_file_path

	SceneSwitcher.change_to_file_with_transition.call_deferred(
		current_scene_path,
		^"",
		Transition.Effect.LEFT_TO_RIGHT_WIPE,
		Transition.Effect.RIGHT_TO_LEFT_WIPE
	)
