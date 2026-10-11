# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StoryQuestProgress

const TIPO_POR_HILO: Array[InventoryItem.ItemType] = [
	InventoryItem.ItemType.MEMORY,
	InventoryItem.ItemType.IMAGINATION,
	InventoryItem.ItemType.SPIRIT,
]
const FRAGMENTOS_POR_HILO: int = 3
const VELOCIDAD_AL_ESCONDERSE: float = 5.0
const VELOCIDAD_AL_REAPARECER: float = 1.4

@export var ocultar: bool = false

var fragmentos_recibidos: int = 0
var _jugador: Player


func _process(delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("player") as Player
	var en_animacion := _jugador != null and _jugador.mode != Player.Mode.USER_CONTROLLED
	var objetivo := 0.0 if en_animacion else 1.0
	var velocidad := VELOCIDAD_AL_ESCONDERSE if en_animacion else VELOCIDAD_AL_REAPARECER
	modulate.a = move_toward(modulate.a, objetivo, velocidad * delta)


# La clase base llama a esta función cada vez que se carga una escena; por eso aquí se
# rellenan los hilos de los niveles anteriores
func update_visibility() -> void:
	var en_quest_con_hilos: bool = GameState.quest and GameState.quest.quest.threads_to_collect > 0
	visible = (player or sokoban_ruleset) and en_quest_con_hilos and not ocultar
	if not visible:
		return

	for slot in items_container.get_children():
		items_container.remove_child(slot)
		slot.queue_free()
	for _i in TIPO_POR_HILO.size():
		items_container.add_child(ITEM_SLOT.instantiate())

	fragmentos_recibidos = GameState.quest.inventory.items.size()
	var hilos_completos: int = fragmentos_recibidos / FRAGMENTOS_POR_HILO
	for indice: int in mini(hilos_completos, TIPO_POR_HILO.size()):
		var slot: ItemSlot = items_container.get_child(indice)
		slot.start_as_filled(InventoryItem.with_type(TIPO_POR_HILO[indice]))

	if not GameState.quest.inventory.item_collected.is_connected(_on_item_collected):
		GameState.quest.inventory.item_collected.connect(_on_item_collected)
	if not GameState.quest.inventory.item_consumed.is_connected(_on_item_consumed):
		GameState.quest.inventory.item_consumed.connect(_on_item_consumed)


func _on_item_collected(_item: InventoryItem) -> void:
	fragmentos_recibidos += 1

	if fragmentos_recibidos % FRAGMENTOS_POR_HILO != 0:
		return
	var indice := fragmentos_recibidos / FRAGMENTOS_POR_HILO - 1
	if indice < TIPO_POR_HILO.size():
		var slot: ItemSlot = items_container.get_child(indice)
		slot.fill(InventoryItem.with_type(TIPO_POR_HILO[indice]))


func _on_item_consumed(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if item_slot.is_filled_with_same_item_type_as(item):
			item_slot.free_slot()
			item_slot.self_modulate = Color.WHITE
