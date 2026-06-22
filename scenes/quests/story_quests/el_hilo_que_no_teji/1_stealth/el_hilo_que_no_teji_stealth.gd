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

	# --- GESTIÓN INICIAL DE LAS ROCAS DEL HILO 3 ---
	var rocas_3 = get_node_or_null("TileMapLayers/RocasBloqueoHilo3")
	if rocas_3:
		if not hilo3_tomado:
			rocas_3.visible = false
			rocas_3.position = Vector2(9999, 9999) 
		else:
			rocas_3.visible = true
			rocas_3.position = Vector2(0, 0)
			
	# --- GESTIÓN INICIAL DE LOS PUENTES Y BLOQUEO INVISIBLE ---
	var puente_roto = get_node_or_null("TileMapLayers/PuenteRoto")
	var puente_normal = get_node_or_null("TileMapLayers/PuenteNormal")
	var bloqueo_puente = get_node_or_null("TileMapLayers/BloqueoPuente") # <--- Referencia al muro
	
	if hilo3_tomado:
		# Si ya se agarró el hilo 3, destruimos el puente roto y la pared invisible
		if puente_roto: puente_roto.queue_free()
		if bloqueo_puente: bloqueo_puente.queue_free()
		
		# Activamos el puente normal
		if puente_normal:
			puente_normal.visible = true
			puente_normal.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		if puente_normal:
			puente_normal.visible = false
			puente_normal.process_mode = Node.PROCESS_MODE_DISABLED

	if hilo1_tomado and has_node("CollectibleItem"):
		$CollectibleItem.queue_free()

	if hilo2_tomado:
		if has_node("CollectibleItem2"):
			$CollectibleItem2.queue_free()
		var rocas_2 = get_node_or_null("TileMapLayers/RocasBloqueoHilo2")
		if rocas_2:
			rocas_2.queue_free()

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
		
		var rocas_2 = get_node_or_null("TileMapLayers/RocasBloqueoHilo2")
		if rocas_2:
			rocas_2.queue_free()

func _on_collectible_item_3_tree_exited() -> void:
	if nivel_apagandose: return
	if not hilo3_tomado:
		hilo3_tomado = true
		hilos_totales += 1
		verificar_progreso()
		
		# --- APARICIÓN DE LAS ROCAS DEL HILO 3 ---
		var rocas_3 = get_node_or_null("TileMapLayers/RocasBloqueoHilo3")
		if rocas_3:
			rocas_3.visible = true
			rocas_3.position = Vector2(0, 0) 
			
		# --- TRANSICIÓN DEL PUENTE Y DESTRUCCIÓN DEL BLOQUEO ---
		var puente_roto = get_node_or_null("TileMapLayers/PuenteRoto")
		var puente_normal = get_node_or_null("TileMapLayers/PuenteNormal")
		var bloqueo_puente = get_node_or_null("TileMapLayers/BloqueoPuente") # <--- Referencia al muro
		
		if puente_roto: puente_roto.queue_free() 
		if bloqueo_puente: bloqueo_puente.queue_free() # Liberamos el paso destruyendo el muro
			
		if puente_normal:
			puente_normal.visible = true
			puente_normal.process_mode = Node.PROCESS_MODE_INHERIT 

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
			SceneSwitcher.change_to_file_with_transition("res://scenes/quests/story_quests/el_hilo_que_no_teji/2_sequence_puzzle/el_hilo_que_no_teji_combat.tscn")
