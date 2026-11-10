# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ReglaHilosHud
extends Node
## Aplica al HUD global del juego la regla de este quest: 3 fragmentos de hilo llenan 1 casilla.
##
## El HUD global llena una casilla por cada objeto recogido. Esta regla no lo reemplaza: cada
## cuadro compara las casillas con lo recogido y las corrige si no coinciden, así no depende de
## en qué momento el HUD arma sus casillas al cargar la escena.

const TIPO_POR_HILO: Array[InventoryItem.ItemType] = [
	InventoryItem.ItemType.MEMORY,
	InventoryItem.ItemType.IMAGINATION,
	InventoryItem.ItemType.SPIRIT,
]
const FRAGMENTOS_POR_HILO: int = 3
## Velocidades (opacidad por segundo) con que el HUD se esconde y reaparece.
const VELOCIDAD_AL_ESCONDERSE: float = 5.0
const VELOCIDAD_AL_REAPARECER: float = 1.4

## Esconde las casillas todo el nivel (por ejemplo en la intro y el outro).
@export var ocultar: bool = false

## Es true mientras una animación pide que el HUD se desvanezca. Se maneja con
## [method ocultar_en_animacion] y se limpia solo al salir o recargar la escena.
static var _oculto_por_animacion: bool = false

var _sincronizado: bool = false


## Desvanece (o devuelve) el HUD completo: las casillas y el contador. Cada animación que
## deba esconderlo lo llama al empezar con true y al terminar con false.
static func ocultar_en_animacion(oculto: bool) -> void:
	_oculto_por_animacion = oculto


func _ready() -> void:
	# Los diálogos pausan el juego: el desvanecido debe seguir mientras tanto.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var casillas: StoryQuestProgress = HUD.story_quest_progress
	if not casillas or not GameState.quest:
		return

	_dejar_de_llenar_por_objeto(casillas)
	casillas.helper_container.visible = false
	if ocultar:
		casillas.visible = false
	if not casillas.visible:
		return

	_corregir_casillas(casillas)
	_desvanecer_en_animaciones(casillas, delta)


func _exit_tree() -> void:
	_oculto_por_animacion = false
	# El HUD global es de todos los quests: se devuelve como estaba al salir de este nivel.
	var casillas: StoryQuestProgress = HUD.story_quest_progress
	if not casillas:
		return
	casillas.modulate.a = 1.0
	casillas.helper_container.visible = GameState.global and GameState.global.helper != null


# La clase base conecta aquí su llenado "una casilla por objeto"; se desconecta para que no
# compita con la regla de este quest.
func _dejar_de_llenar_por_objeto(casillas: StoryQuestProgress) -> void:
	var recogidos := GameState.quest.inventory.item_collected
	if recogidos.is_connected(casillas._on_item_collected):
		recogidos.disconnect(casillas._on_item_collected)


func _corregir_casillas(casillas: StoryQuestProgress) -> void:
	var casillas_hijas := casillas.items_container.get_children()
	if casillas_hijas.is_empty():
		return

	var hilos_completos := mini(
		GameState.quest.inventory.items.size() / FRAGMENTOS_POR_HILO, TIPO_POR_HILO.size()
	)
	var llenas := 0
	var coinciden := casillas_hijas.size() == TIPO_POR_HILO.size()
	for indice in casillas_hijas.size():
		var casilla := casillas_hijas[indice] as ItemSlot
		if casilla.is_filled():
			llenas += 1
		if indice >= TIPO_POR_HILO.size():
			continue
		var debe_estar_llena := indice < hilos_completos
		if casilla.is_filled() != debe_estar_llena:
			coinciden = false
		elif casilla.is_filled() and casilla.filled_with_item.type != TIPO_POR_HILO[indice]:
			coinciden = false

	if coinciden:
		_sincronizado = true
		return

	# Un hilo recién completado se llena con animación; cualquier otro desajuste se rehace.
	if _sincronizado and llenas == hilos_completos - 1 and hilos_completos <= casillas_hijas.size():
		var nueva := casillas_hijas[hilos_completos - 1] as ItemSlot
		if not nueva.is_filled():
			nueva.fill(InventoryItem.with_type(TIPO_POR_HILO[hilos_completos - 1]))
			return
	_rehacer_casillas(casillas, hilos_completos)
	_sincronizado = true


func _rehacer_casillas(casillas: StoryQuestProgress, hilos_completos: int) -> void:
	for casilla in casillas.items_container.get_children():
		casillas.items_container.remove_child(casilla)
		casilla.queue_free()
	for indice in TIPO_POR_HILO.size():
		var casilla := StoryQuestProgress.ITEM_SLOT.instantiate() as ItemSlot
		casillas.items_container.add_child(casilla)
		if indice < hilos_completos:
			casilla.start_as_filled(InventoryItem.with_type(TIPO_POR_HILO[indice]))


# El HUD solo se apaga mientras una animación lo pide; fuera de eso siempre se ve.
func _desvanecer_en_animaciones(casillas: StoryQuestProgress, delta: float) -> void:
	var objetivo := 0.0 if _oculto_por_animacion else 1.0
	var velocidad := VELOCIDAD_AL_ESCONDERSE if _oculto_por_animacion else VELOCIDAD_AL_REAPARECER
	casillas.modulate.a = move_toward(casillas.modulate.a, objetivo, velocidad * delta)
	# El contador de fragmentos (el "1/3") es un hermano de este nodo: se apaga con las casillas.
	var contador := get_parent().get_node_or_null(^"Label") as CanvasItem
	if contador:
		contador.modulate.a = casillas.modulate.a
