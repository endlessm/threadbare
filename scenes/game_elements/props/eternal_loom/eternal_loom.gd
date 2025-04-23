# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const ETERNAL_LOOM_INTERACTION: DialogueResource = preload(
	"res://scenes/game_elements/props/eternal_loom/eternal_loom_interaction.dialogue"
)
const ETERNAL_LOOM_SOKOBAN_PATH = "res://scenes/eternal_loom_sokoban/eternal_loom_sokoban.tscn"

@onready var interact_area: InteractArea = %InteractArea
@onready var loom_offering_animation_player: AnimationPlayer = %LoomOfferingAnimationPlayer


func _ready():
	interact_area.interaction_started.connect(self._on_interacted)


func _on_interacted(player: Player, _from_right: bool) -> void:
	DialogueManager.show_dialogue_balloon(ETERNAL_LOOM_INTERACTION, "", [self, player])
	await DialogueManager.dialogue_ended

	# This little wait is needed to avoid triggering another dialogue:
	# TODO: improve this in https://github.com/endlessm/threadbare/issues/103
	await get_tree().create_timer(0.3).timeout
	interact_area.end_interaction()


func on_offering_succeeded():
	var items_collected: Array[InventoryItem] = GameState.items_collected()
	loom_offering_animation_player.play(&"loom_offering")
	await loom_offering_animation_player.animation_finished

	_consume_items_offering(items_collected)


func _item_types_required() -> Array:
	return [
		InventoryItem.ItemType.MEMORY,
		InventoryItem.ItemType.IMAGINATION,
		InventoryItem.ItemType.SPIRIT
	]


func is_item_offering_possible() -> bool:
	var items_collected: Array[InventoryItem] = GameState.items_collected()
	return _item_types_required().all(
		func(item_type): return _is_there_item_of_type(items_collected, item_type)
	)


func _consume_items_offering(items_collected: Array[InventoryItem]) -> void:
	for item_type in _item_types_required():
		var item = _find_first_item_of_type(items_collected, item_type)
		GameState.remove_consumed_item(item)


func _is_there_item_of_type(
	items_collected: Array[InventoryItem], expected_type: InventoryItem.ItemType
) -> bool:
	return _find_first_item_of_type(items_collected, expected_type) != null


func _find_first_item_of_type(
	items_collected: Array[InventoryItem], expected_type: InventoryItem.ItemType
) -> InventoryItem:
	for item: InventoryItem in items_collected:
		if item.type == expected_type:
			return item
	return null
