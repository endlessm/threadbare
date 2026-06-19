# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const DIALOGO_STEALTH = preload("res://scenes/quests/story_quests/el_hilo_que_no_teji/1_stealth/stealth_components/el_hilo_que_no_teji_stealth.dialogue")

@onready var sonido_ladrido = $ZonaClimax/LadridoLuto
@onready var particulas_doradas = $TileMapLayers/Tree/ParticulasDoradas
@onready var flecha = $TileMapLayers/Tree/Flecha

static var hilos_totales = 0
static var hilo1_tomado = false
static var hilo2_tomado = false
static var hilo3_tomado = false

var nivel_apagandose = false

func _ready():
	nivel_apagandose = false
	self.tree_exiting.connect(_activar_escudo)

	if hilo1_tomado and has_node("CollectibleItem"):
		$CollectibleItem.queue_free()

	if hilo2_tomado and has_node("CollectibleItem2"):
		$CollectibleItem2.queue_free()
		# Nos aseguramos de que las rocas no aparezcan al recargar si ya agarró el hilo 2
		if has_node("TileMapLayers/SmallStones"):
			$TileMapLayers/SmallStones.queue_free()

	if hilo3_tomado and has_node("CollectibleItem3"):
		$CollectibleItem3.queue_free()

	verificar_progreso()

func verificar_progreso():
	if hilos_totales >= 3 and flecha:
		flecha.visible = true

func _activar_escudo():
	nivel_apagandose = true

func _on_collectible_item_tree_exited() -> void:
	if nivel_apagandose: return
	if not hilo1_tomado:
		hilo1_tomado = true
		hilos_totales += 1
		verificar_progreso()

func _on_collectible_item_2_tree_exited() -> void:
	if nivel_apagandose: return
	if not hilo2_tomado:
		hilo2_tomado = true
		hilos_totales += 1
		verificar_progreso()
		
		# --- DESTRUCCIÓN DE LAS ROCAS ---
		var rocas = get_node_or_null("TileMapLayers/SmallStones")
		if rocas:
			rocas.queue_free()

func _on_collectible_item_3_tree_exited() -> void:
	if nivel_apagandose: return
	if not hilo3_tomado:
		hilo3_tomado = true
		hilos_totales += 1
		verificar_progreso()

func _on_zona_climax_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if hilos_totales >= 3:
			body.velocity = Vector2.ZERO
			body.take_control(self)
			$ZonaClimax.set_deferred("monitoring", false)

			if has_node("EnemyGuards"):
				$EnemyGuards.queue_free()

			particulas_doradas.emitting = true
			if flecha: flecha.visible = false

			DialogueManager.show_dialogue_balloon(DIALOGO_STEALTH, "arbol_climax")
			await DialogueManager.dialogue_ended
			SceneSwitcher.change_to_file_with_transition("res://scenes/quests/story_quests/el_hilo_que_no_teji/2_sequence_puzzle/el_hilo_que_no_teji_sequence_puzzle.tscn")
