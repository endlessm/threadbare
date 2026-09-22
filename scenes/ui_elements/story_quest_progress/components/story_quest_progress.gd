# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name StoryQuestProgress
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")
const TOWNIE = preload("uid://dgrrudegturnw")

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var helper_container: CenterContainer = %HelperContainer
@onready var helper_marker: Marker2D = %HelperMarker
@onready var helper_color: ColorRect = %HelperColor

var _helper_global: GlobalState


## Rebuild slots from [member GameState.quest] when the scene changes.
func refresh() -> void:
	_bind_helper_changed()

	var n := 0
	if GameState.quest:
		n = GameState.quest.quest.threads_to_collect

	if n == 0:
		visible = false
	else:
		# Rebuild slots only when the quest needs a different number of them.
		if items_container.get_child_count() != n:
			for child in items_container.get_children():
				items_container.remove_child(child)
				child.free()

			# Add one slot for each item in the current quest
			for _i: int in n:
				items_container.add_child(ITEM_SLOT.instantiate())

		var inventory := GameState.quest.inventory
		if inventory.item_collected.is_connected(_on_item_collected):
			inventory.item_collected.disconnect(_on_item_collected)
		if inventory.item_consumed.is_connected(_on_item_consumed):
			inventory.item_consumed.disconnect(_on_item_consumed)

		# Populate the HUD with the items that were collected so far in the quest.
		var items_collected := inventory.items
		for i: int in min(items_collected.size(), n):
			items_container.get_child(i).start_as_filled(items_collected[i])

		# Then, when each new item is collected, it is added to the progress UI
		inventory.item_collected.connect(self._on_item_collected)
		inventory.item_consumed.connect(self._on_item_consumed)

	_on_helper_state_changed()


func _bind_helper_changed() -> void:
	if _helper_global == GameState.global:
		return
	if _helper_global:
		_helper_global.helper_changed.disconnect(_on_helper_state_changed)
	_helper_global = GameState.global
	_helper_global.helper_changed.connect(_on_helper_state_changed)


func _on_helper_state_changed() -> void:
	for child in helper_container.get_children():
		if child == helper_marker or child == helper_color:
			continue
		child.queue_free()

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
