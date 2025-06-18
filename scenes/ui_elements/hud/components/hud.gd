extends CanvasLayer
@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var items_container: HBoxContainer = $StoryQuestProgress/ItemsContainer

func _load_collected_items() -> void:
	var inventory_items := GameState.items_collected()
	var slots := items_container.get_children()  # ← Aquí corregido

	for i in range(inventory_items.size()):
		if i >= slots.size():
			break

		var slot = slots[i]
		if slot is ItemSlot:
			slot.start_as_filled(inventory_items[i])

func reload_items() -> void:
	_load_collected_items()

func _ready() -> void:
	GameState.collected_items_changed.connect(_on_collected_items_changed)
	_load_collected_items()

func _on_collected_items_changed(_items: Array[InventoryItem]) -> void:
	_load_collected_items()
