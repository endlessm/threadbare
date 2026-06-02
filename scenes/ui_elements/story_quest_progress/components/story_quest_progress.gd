# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")
const TOWNIE = preload("uid://dgrrudegturnw")

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var helper_container: CenterContainer = %HelperContainer
@onready var helper_marker: Marker2D = %HelperMarker
@onready var helper_color: ColorRect = %HelperColor


func _ready() -> void:
	GameState.global.helper_changed.connect(_on_helper_state_changed)
	_on_helper_state_changed()

	var n := 0
	if GameState.quest:
		n = GameState.quest.quest.threads_to_collect

	if n == 0:
		visible = false
		return

	# Add one slot for each item in the current quest
	for _i: int in n:
		items_container.add_child(ITEM_SLOT.instantiate())

	# On ready, the HUD is populated with the items that were collected so
	# far in the quest.
	var items_collected := GameState.global.inventory
	for i: int in min(items_collected.size(), n):
		items_container.get_child(i).start_as_filled(items_collected[i])

	# Then, when each new item is collected, it is added to the progress UI
	GameState.global.item_collected.connect(self._on_item_collected)
	GameState.global.item_consumed.connect(self._on_item_consumed)


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
