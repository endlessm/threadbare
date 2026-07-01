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
	# Desactivamos el gancho (apuntar/lanzar) específicamente para este nivel
	GameState.set_ability(Enums.PlayerAbilities.ABILITY_B, false)
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

# =========================================================
# CINEMÁTICA DEL HILO 2 ACTUALIZADA (CON FOCO DE CÁMARA)
# =========================================================
# =========================================================
# CINEMÁTICA DEL HILO 2 ACTUALIZADA (DESINTEGRACIÓN MÁGICA)
# =========================================================
func _on_collectible_item_2_tree_exited() -> void:
	if nivel_apagandose: return
	if not hilo2_tomado:
		# 1. Guardamos el progreso normalmente
		hilo2_tomado = true
		hilos_totales += 1
		verificar_progreso()
		
		# 2. Buscamos a Lino, las Rocas y el nuevo Marcador
		var jugadores = get_tree().get_nodes_in_group("player")
		if jugadores.is_empty(): return
		var lino = jugadores[0]
		
		var rocas_2 = get_node_or_null("TileMapLayers/RocasBloqueoHilo2")
		var foco_camara = get_node_or_null("TileMapLayers/FocoCamaraRocas2") 
		if not rocas_2: return

		# 3. Congelar a Lino de forma segura
		if lino.has_method("take_control"):
			lino.take_control(self)
		lino.velocity = Vector2.ZERO

		# 4. Configurar cámara
		var camara = get_viewport().get_camera_2d()
		var zoom_original = camara.zoom
		var suavizado_original = camara.position_smoothing_enabled
		camara.position_smoothing_enabled = false

		# 5. La Cinemática
		var cinematica = create_tween()
		var destino_camara = foco_camara.global_position if foco_camara else rocas_2.global_position
		
		# Viaje dramático hacia el marcador
		cinematica.tween_property(camara, "global_position", destino_camara, 1.2).set_trans(Tween.TRANS_SINE)
		cinematica.parallel().tween_property(camara, "zoom", Vector2(1.4, 1.4), 1.2)
		cinematica.chain().tween_interval(0.3) # Pequeña pausa de silencio antes del caos
		
		# =======================================================
		# FASE B: Terremoto Escalado y Desintegración Mágica
		# =======================================================
		var pos_original = rocas_2.position
		
		# 1. Temblor que aumenta de intensidad (1.2 segundos de pura tensión)
		for i in range(24):
			var intensidad = float(i) / 24.0 # Va de 0.0 (suave) a 1.0 (violento)
			var fuerza_x = randf_range(-1.0, 1.0) + (randf_range(-4.0, 4.0) * intensidad)
			var fuerza_y = randf_range(-1.0, 1.0) + (randf_range(-2.0, 2.0) * intensidad)
			cinematica.tween_property(rocas_2, "position", pos_original + Vector2(fuerza_x, fuerza_y), 0.05)
		
		# 2. Hack maestro: Apagamos el shader y damos un destello blanco de energía
		cinematica.tween_callback(func():
			if is_instance_valid(rocas_2):
				rocas_2.material = null # Liberamos la transparencia
				rocas_2.modulate = Color(2.0, 2.0, 2.0, 1.0) # Flash de luz blanca
		)
		
		# 3. Desintegración: Flotan hacia arriba como polvo y se desvanecen (0.6 seg)
		cinematica.tween_property(rocas_2, "position", pos_original + Vector2(0, -15), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		cinematica.parallel().tween_property(rocas_2, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.6)
		
		# 4. Eliminación final del nodo
		cinematica.tween_callback(rocas_2.queue_free)
		# =======================================================
		
		# Pausa para que el jugador procese que el camino está libre
		cinematica.tween_interval(0.8)
		
		# Regreso rápido a Lino
		cinematica.tween_property(camara, "global_position", lino.global_position, 0.8).set_trans(Tween.TRANS_QUAD)
		cinematica.parallel().tween_property(camara, "zoom", zoom_original, 0.8)

		await cinematica.finished

		# 6. Restaurar cámara y control
		camara.position_smoothing_enabled = suavizado_original
		camara.global_position = lino.global_position 
		
		if lino.has_method("return_control"):
			lino.return_control(self)

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
			SceneSwitcher.change_to_file_with_transition("res://scenes/quests/story_quests/el_hilo_que_no_teji/2_sequence_puzzle/el_hilo_que_no_teji_sequence_puzzle.tscn")
