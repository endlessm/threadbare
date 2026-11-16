# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name FillGameLogic
extends Node
## Manages the logic of the fill-matching game.
##
## @tutorial: https://github.com/endlessm/threadbare/discussions/1323
##
## This is a piece of the fill-matching mechanic.
## [br][br]
## Grabs the label and optional color of each [FillingBarrel] that exist in the
## current scene, and assigns them as the allowed label/color of the [Projectile]
## that each [ThrowingEnemy] is allowed to throw.
## Each time a [FillingBarrel] is filled, perform the label/color assignment again
## so [ThrowingEnemy]s only throw projectiles that can increase the amount of
## the remaining barrels.
## [br][br]
## Also keep track of the completed [FillingBarrel]s and emit [signal goal_reached]
## when [member barrels_to_win] is reached.

## Emited when [member barrels_completed] reaches [member barrels_to_win].
signal goal_reached

## How many barrels to complete for winning.
@export var barrels_to_win: int = 1

@export var intro_dialogue: DialogueResource

## Counter for the completed barrels.
var barrels_completed: int = 0


func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING
	get_tree().call_group("throwing_enemy", "start")
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		filling_barrel.completed.connect(_on_barrel_completed)
	_update_allowed_colors()


func _ready() -> void:
	var filling_barrels: Array = get_tree().get_nodes_in_group("filling_barrels")
	barrels_to_win = clampi(barrels_to_win, 0, filling_barrels.size())
	if intro_dialogue:
		var player: Player = get_tree().get_first_node_in_group("player")
		DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self, player])
		await DialogueManager.dialogue_ended
	start()


func _update_allowed_colors() -> void:
	var allowed_labels: Array[String] = []
	var color_per_label: Dictionary[String, Color]
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		if filling_barrel.is_queued_for_deletion():
			continue
		if filling_barrel.label not in allowed_labels:
			allowed_labels.append(filling_barrel.label)
			if not filling_barrel.color:
				continue
			color_per_label[filling_barrel.label] = filling_barrel.color
	for enemy: ThrowingEnemy in get_tree().get_nodes_in_group("throwing_enemy"):
		enemy.allowed_labels = allowed_labels
		enemy.color_per_label = color_per_label


func _on_barrel_completed() -> void:
	barrels_completed += 1
	_update_allowed_colors()
	if barrels_completed < barrels_to_win:
		return
	get_tree().call_group("throwing_enemy", "remove")
	get_tree().call_group("projectiles", "remove")
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY
	goal_reached.emit()
