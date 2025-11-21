# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VaseDestructionTracker
extends Node2D

## Name of the group to monitor. If all nodes in this group are destroyed, Game Over triggers.
@export var target_group_name: String = "Vases"

var total_targets: int = 0
var destroyed_count: int = 0


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
	destroyed_count += 1
	print("Object destroyed. Progress: %d/%d" % [destroyed_count, total_targets])
	check_loss_condition()


func check_loss_condition() -> void:
	if destroyed_count >= total_targets:
		trigger_game_over()


func trigger_game_over() -> void:
	print("GAME OVER - All targets in group '%s' destroyed." % target_group_name)
	get_tree().reload_current_scene()
