# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name FillGameLogic
extends Node

signal goal_reached

@export var intro_dialogue: DialogueResource

# Define el orden correcto según el acertijo (nombres exactos de los nodos)
const CORRECT_ORDER := ["Target4", "Target3", "Target1"]
var current_index := 0

@onready var collectible_item := $CollectibleItem

func _ready() -> void:
	if collectible_item:
		collectible_item.visible = false

	if intro_dialogue:
		var player: Player = get_tree().get_first_node_in_group("player")
		DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self, player])
		await DialogueManager.dialogue_ended
	start()


func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING

	get_tree().call_group("throwing_enemy", "start")

	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		filling_barrel.completed.connect(_on_barrel_completed.bind(filling_barrel.name))

	_update_allowed_colors()


func _on_barrel_completed(barrel_name: StringName) -> void:
	if barrel_name == CORRECT_ORDER[current_index]:
		current_index += 1
		if current_index == CORRECT_ORDER.size():
			_on_puzzle_completed()
	else:
		_restart_puzzle()


func _on_puzzle_completed() -> void:
	get_tree().call_group("throwing_enemy", "remove")
	get_tree().call_group("projectiles", "remove")

	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY

	if collectible_item:
		collectible_item.visible = true

	goal_reached.emit()


func _restart_puzzle() -> void:
	# Recarga la escena para reiniciar todo
	get_tree().reload_current_scene()


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
