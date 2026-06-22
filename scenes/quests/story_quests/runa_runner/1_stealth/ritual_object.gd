# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

## Dialogue resource with the "final_recogido" node, shown when this is the last ritual object.
@export var dialogue: DialogueResource

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	await _check_all_collected(body)
	queue_free()

func _check_all_collected(player: Player) -> void:
	var remaining := get_tree().get_nodes_in_group("ritual_object")
	remaining.erase(self)

	if remaining.is_empty():
		# Este era el último ritual object: mostramos el diálogo antes de revelar
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, "final_recogido", [self, player])
			await DialogueManager.dialogue_ended

		var finals := get_tree().get_nodes_in_group("final_collectible")
		for f in finals:
			if f.has_method("reveal"):
				f.reveal()
