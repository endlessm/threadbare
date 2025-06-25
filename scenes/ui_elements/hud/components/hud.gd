extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var items_container: HBoxContainer = $StoryQuestProgress/ItemsContainer_Personajes

func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility

func _load_collected_items() -> void:
	var inventory_items := GameState.items_collected()
	var personajes := inventory_items.filter(func(item): return item.source_game > 0)
	var slots := items_container.get_children()

	for slot in slots:
		if slot is ItemSlot:
			slot.free_slot()

	for i in range(personajes.size()):
		if i >= slots.size():
			break

		var slot = slots[i]
		if slot is ItemSlot:
			slot.start_as_filled(personajes[i])


func reload_items() -> void:
	_load_collected_items()

func _ready() -> void:
	GameState.collected_items_changed.connect(_on_collected_items_changed)
	GameState.item_collected.connect(_on_item_collected)  # ← Esto filtra personajes
	_load_collected_items()

func _on_collected_items_changed(_items: Array[InventoryItem]) -> void:
	_load_collected_items()
	
func _on_item_collected(item: InventoryItem) -> void:
	# Asegúrate de que solo personajes pasen
	if item.source_game <= 0:
		return  # Ignorar objetos u otros

	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if not item_slot.is_filled():
			item_slot.fill(item)
			return
