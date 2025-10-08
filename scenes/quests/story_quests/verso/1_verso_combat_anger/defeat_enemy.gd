# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
@export var intro_dialogue: DialogueResource

var enemies_left: int = 6

signal goal_reached

func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING
	get_tree().call_group("throwing_enemy", "start")
	
	
func _ready() -> void:
	if intro_dialogue:
		var player: Player = get_tree().get_first_node_in_group("player")
		DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self, player])
		await DialogueManager.dialogue_ended
	start()

func _update_allowed_colors() -> void:
	var allowed_labels: Array[String] = []
	var color_per_label: Dictionary[String, Color]
	for enemy: ThrowingEnemy in get_tree().get_nodes_in_group("throwing_enemy"):
		enemy.allowed_labels = allowed_labels
		enemy.color_per_label = color_per_label


func _on_enemy_defeated() -> void:
	enemies_left -= 1
	if enemies_left <= 0:
		var player: Player = get_tree().get_first_node_in_group("player")
		if player:
			player.mode = Player.Mode.COZY
		goal_reached.emit()
