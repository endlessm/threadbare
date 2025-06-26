extends "res://scenes/game_elements/props/collectible_item/components/collectible_item.gd"  # Usa la ruta al original

func _on_interacted(player: Player, _from_right: bool) -> void:
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished

	# No usar GameState, sino mandar directamente al HUD
	if item is CustomInventoryItem and item.target_hud == "SecondaryHUD":
		var hud = get_tree().get_current_scene().find_child("SecondaryHUD", true, false)
		if hud:
			hud.add_item(item)
	else:
		GameState.add_collected_item(item)

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	queue_free()

	if next_scene:
		SceneSwitcher.change_to_file_with_transition(next_scene)
