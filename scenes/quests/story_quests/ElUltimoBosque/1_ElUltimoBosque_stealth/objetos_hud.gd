extends CanvasLayer
@onready var objetos_panel: PanelContainer = $ObjetosPanel

@onready var items_container: HBoxContainer = $ObjetosPanel/ItemsContainer_Objetos

func _ready() -> void:
	GameState.collected_items_changed.connect(_on_collected_items_changed)
	_load_object_items()

func _on_collected_items_changed(_items: Array[InventoryItem]) -> void:
	_load_object_items()
func _load_object_items() -> void:
	var inventory_items := GameState.items_collected()
	var objetos := inventory_items.filter(func(item):
		return item.type in [
			InventoryItem.ItemType.GLOVE,
			InventoryItem.ItemType.SHOES,
			InventoryItem.ItemType.BELT
		]
	)
	var slots := items_container.get_children()

	# Limpiar todos los slots antes de rellenar
	for slot in slots:
		if slot is ItemSlot:
			slot.free_slot()

	for i in range(objetos.size()):
		if i >= slots.size():
			break

		var slot = slots[i]
		if slot is ItemSlot:
			slot.start_as_filled(objetos[i])
