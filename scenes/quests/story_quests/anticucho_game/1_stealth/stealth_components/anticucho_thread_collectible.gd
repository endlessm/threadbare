# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name AnticuchoThreadCollectible
extends CollectibleItem

signal collected_in_stealth


func _ready() -> void:
	super._ready()
	add_to_group(&"anticucho_stealth_threads")


func _on_interacted(player: Player, from_right: bool) -> void:
	z_index += 1
	animation_player.play(&"collected")
	await animation_player.animation_finished

	GameState.add_collected_item(item)

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	collected_in_stealth.emit()
	queue_free()
