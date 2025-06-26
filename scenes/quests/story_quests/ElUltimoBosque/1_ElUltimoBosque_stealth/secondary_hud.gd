extends Control

@onready var slots: Array[TextureRect] = [
	$HBoxContainer/ObjectSlot1,
	$HBoxContainer/ObjectSlot2,
	$HBoxContainer/ObjectSlot3
]

signal all_items_collected  # ✅ NUEVA SEÑAL

var current_index := 0

func add_item(item: InventoryItem) -> void:
	if current_index < slots.size():
		slots[current_index].texture = item.texture()
		current_index += 1
	
	if current_index == slots.size():
			print("✅ Se recogieron los 3 objetos secundarios")
			emit_signal("all_items_collected")  # ✅ EMITE SEÑAL
