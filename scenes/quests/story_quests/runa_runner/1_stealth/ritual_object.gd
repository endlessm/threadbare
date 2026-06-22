# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

## Dialogue resource with the "final_recogido" node, shown when this is the last ritual object.
@export var dialogue: DialogueResource

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null:
		return
	await _check_all_collected(player)
	queue_free()

func _check_all_collected(player: Player) -> void:
	var remaining: Array[Node] = get_tree().get_nodes_in_group(&"ritual_object")
	remaining.erase(self)

	if remaining.is_empty():
		# Este era el último ritual object: mostramos el diálogo antes de revelar
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, "final_recogido", [self, player])
			await DialogueManager.dialogue_ended

		var finals: Array[Node] = get_tree().get_nodes_in_group(&"final_collectible")
		for final_item: Node in finals:
			if final_item.has_method("reveal"):
				final_item.call("reveal")
