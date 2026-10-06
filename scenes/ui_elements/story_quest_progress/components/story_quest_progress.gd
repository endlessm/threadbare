# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name StoryQuestProgress
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")
const TOWNIE = preload("uid://dgrrudegturnw")

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var helper_container: CenterContainer = %HelperContainer
@onready var helper_marker: Marker2D = %HelperMarker
@onready var helper_color: ColorRect = %HelperColor


func _ready() -> void:
	GameState.cleared.connect(_on_gamestate_cleared)
	_on_gamestate_cleared()


func _on_gamestate_cleared() -> void:
	GameState.global.helper_changed.connect(_on_helper_state_changed)
	_on_helper_state_changed()


func update_visibility() -> void:
	var in_a_quest_with_threads_to_collect := (
		GameState.quest and GameState.quest.quest.threads_to_collect
	)
	visible = (
		(player or sokoban_ruleset)
		and (in_a_quest_with_threads_to_collect or GameState.is_item_offering_possible())
	)
	if not visible:
		return

	var threads_to_collect := GameState.quest.quest.threads_to_collect

	# Add one slot for each item in the current quest.
	for i in items_container.get_children():
		items_container.remove_child(i)
		i.queue_free()
	for _i: int in threads_to_collect:
		items_container.add_child(ITEM_SLOT.instantiate())

	var items_collected := GameState.quest.inventory.items
	for i: int in min(items_collected.size(), threads_to_collect):
		var item_slot: ItemSlot = items_container.get_child(i) as ItemSlot
		item_slot.start_as_filled(items_collected[i])

	# When each new item is collected, it is added to the progress UI.
	if not GameState.quest.inventory.item_collected.is_connected(self._on_item_collected):
		GameState.quest.inventory.item_collected.connect(self._on_item_collected)
	if not GameState.quest.inventory.item_consumed.is_connected(self._on_item_consumed):
		GameState.quest.inventory.item_consumed.connect(self._on_item_consumed)


func _on_helper_state_changed() -> void:
	var has_helper := GameState.global.helper != null
	helper_container.visible = has_helper
	if has_helper:
		var helper_character: CharacterRandomizer = TOWNIE.instantiate()
		add_child(helper_character)
		helper_character.character_seed = GameState.global.helper.character_seed
		helper_character.apply_character_randomizations()
		var head := helper_character.head
		head.global_position = helper_marker.global_position
		head.reparent(helper_container)
		head.process_mode = Node.PROCESS_MODE_DISABLED
		remove_child(helper_character)
		helper_color.color = InventoryItem.COLORS_PER_TYPE[GameState.global.helper.helper_type]


func _on_item_collected(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if not item_slot.is_filled():
			item_slot.fill(item)
			return


func _on_item_consumed(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if item_slot.is_filled_with_same_item_type_as(item):
			item_slot.free_slot()
			return
