# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# --- VARIABLES ESTÁTICAS DE GUARDADO (SOBREVIVEN AL REINICIO) ---
static var estado_hilo_izq: bool = false
static var estado_hilo_der: bool = false
static var estado_hilo_central: bool = false

const MAX_GOLPES: int = 5
var golpes_recibidos: int = 0
var primer_golpe_recibido: bool = false
var texto_central_mostrado: bool = false
var lino_muerto: bool = false

var jarrones_izq_completados: int = 0
var jarrones_der_completados: int = 0
var hilos_recogidos: int = 0
var alas_limpiadas: int = 0

# 1. REFERENCIAS DE LINO Y UI
@onready var jugador = $OnTheGround/Player
@onready var sprite_jugador = jugador.get_node("%PlayerSprite")
@onready var hitbox_jugador = jugador.get_node("PlayerHarm/HitBox")
@onready var panel_pensamiento = $HUD/PanelContainer
@onready var canvas_modulate = $CanvasModulate

# 2. REFERENCIAS DE PUERTAS Y HILOS
@onready var puerta_central = $"OnTheGround/Door Enter"
@onready var puerta_salida = $"OnTheGround/LevelExit/Door Exit"

@onready var hilo_izq = $OnTheGround/CollectibleItem_Izq
@onready var hilo_der = $OnTheGround/CollectibleItem_Der
@onready var hilo_central = $OnTheGround/CollectibleItem_Centro

# 3. REFERENCIAS DE ENEMIGOS, JARRONES Y VFX
@onready var enemigo_1 = $OnTheGround/ThrowingEnemy
@onready var enemigo_2 = $OnTheGround/ThrowingEnemy2
@onready var enemigo_3 = $OnTheGround/ThrowingEnemy3
@onready var enemigo_4 = $OnTheGround/ThrowingEnemy4
@onready var enemigo_5 = $OnTheGround/ThrowingEnemy5
@onready var enemigo_6 = $OnTheGround/ThrowingEnemy6
@onready var enemigo_7 = $OnTheGround/ThrowingEnemy7
@onready var enemigo_8 = $OnTheGround/ThrowingEnemy8

@onready var jarrones_izq = [$OnTheGround/FillingBarrel, $OnTheGround/FillingBarrel2]
@onready var jarrones_der = [$OnTheGround/FillingBarrel3, $OnTheGround/FillingBarrel4]
@onready var jarron_central = $OnTheGround/FillingBarrel5

@onready var particulas_perdon = $OnTheGround/ParticulasPerdon

var material_gris: ShaderMaterial

func _ready() -> void:
	var shader = preload("res://scenes/quests/story_quests/el_hilo_que_no_teji/3_combat/filtro_gris.gdshader")
	material_gris = ShaderMaterial.new()
	material_gris.shader = shader
	sprite_jugador.material = material_gris
	sprite_jugador.sprite_frames.set_animation_loop("defeated", false)
	
	hitbox_jugador.body_entered.connect(_al_recibir_bolita)
	
	var color_tristeza = Color(0.6, 0.6, 0.6)
	var arreglo_etiquetas: Array[String] = ["Ira"]
	var diccionario_colores: Dictionary[String, Color] = {"Ira": color_tristeza}
	
	var todos_los_enemigos = [enemigo_1, enemigo_2, enemigo_3, enemigo_4, enemigo_5, enemigo_6, enemigo_7, enemigo_8]
	for enemigo in todos_los_enemigos:
		if is_instance_valid(enemigo):
			enemigo.allowed_labels = arreglo_etiquetas
			enemigo.color_per_label = diccionario_colores
			
	for jarron in jarrones_izq:
		if is_instance_valid(jarron): jarron.completed.connect(_al_completar_jarron_izq)
	for jarron in jarrones_der:
		if is_instance_valid(jarron): jarron.completed.connect(_al_completar_jarron_der)
	if is_instance_valid(jarron_central):
		jarron_central.completed.connect(_al_completar_jarron_central)

	# --- RECUPERAR EL PROGRESO GUARDADO AL REINICIAR ---
	if estado_hilo_izq:
		_limpiar_ala_izq_guardada()
		if is_instance_valid(hilo_izq): hilo_izq.queue_free()
		hilos_recogidos += 1
		alas_limpiadas += 1
	elif is_instance_valid(hilo_izq): 
		hilo_izq.revealed = false
		hilo_izq.tree_exited.connect(_al_recoger_hilo.bind("izq"))

	if estado_hilo_der:
		_limpiar_ala_der_guardada()
		if is_instance_valid(hilo_der): hilo_der.queue_free()
		hilos_recogidos += 1
		alas_limpiadas += 1
	elif is_instance_valid(hilo_der): 
		hilo_der.revealed = false
		hilo_der.tree_exited.connect(_al_recoger_hilo.bind("der"))

	if estado_hilo_central:
		if is_instance_valid(jarron_central): jarron_central.queue_free()
		if is_instance_valid(hilo_central): hilo_central.queue_free()
		hilos_recogidos += 1
	elif is_instance_valid(hilo_central): 
		hilo_central.revealed = false
		hilo_central.tree_exited.connect(_al_recoger_hilo.bind("central"))

	_actualizar_color_ambiente()
	
	# Restaurar estado de las puertas si ya teníamos los hilos
	if hilos_recogidos >= 2 and is_instance_valid(puerta_central):
		puerta_central.open()
	if hilos_recogidos >= 3 and is_instance_valid(puerta_salida):
		puerta_salida.open()

# --- FUNCIONES PARA LIMPIAR ALAS YA COMPLETADAS ---
func _limpiar_ala_izq_guardada() -> void:
	if is_instance_valid(enemigo_1): enemigo_1.queue_free()
	if is_instance_valid(enemigo_2): enemigo_2.queue_free()
	for jarron in jarrones_izq:
		if is_instance_valid(jarron): jarron.queue_free()

func _limpiar_ala_der_guardada() -> void:
	if is_instance_valid(enemigo_3): enemigo_3.queue_free()
	if is_instance_valid(enemigo_4): enemigo_4.queue_free()
	for jarron in jarrones_der:
		if is_instance_valid(jarron): jarron.queue_free()

# --- SISTEMA DEL MUNDO ---
func _actualizar_color_ambiente() -> void:
	if not is_instance_valid(canvas_modulate): return
	match hilos_recogidos:
		0: canvas_modulate.color = Color(0.4, 0.4, 0.4)
		1: canvas_modulate.color = Color(0.6, 0.6, 0.6)
		2: canvas_modulate.color = Color(0.8, 0.8, 0.8)
		3: canvas_modulate.color = Color(1.0, 1.0, 1.0)

func _sacudir_pantalla() -> void:
	var camara = get_viewport().get_camera_2d()
	if is_instance_valid(camara):
		var tween = create_tween()
		for i in range(10):
			tween.tween_property(camara, "offset", Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.05)
		tween.tween_property(camara, "offset", Vector2.ZERO, 0.05)

# Se añadió el identificador para saber cuál hilo guardamos
# Se añadió el identificador para saber cuál hilo guardamos
func _al_recoger_hilo(id_hilo: String = "") -> void:
	if not is_inside_tree(): return
	
	# Guardamos el estado estático
	match id_hilo:
		"izq": estado_hilo_izq = true
		"der": estado_hilo_der = true
		"central": estado_hilo_central = true
		
	hilos_recogidos += 1
	_actualizar_color_ambiente()
	
	if hilos_recogidos == 2:
		# ---> ¡AQUÍ ESTÁ LA MAGIA! En vez de abrir de golpe, llamamos a la cinemática
		_cinematica_apertura_puerta()
			
	elif hilos_recogidos == 3:
		if is_instance_valid(particulas_perdon):
			particulas_perdon.emitting = true
		_sacudir_pantalla()
		
		if is_instance_valid(puerta_salida):
			puerta_salida.open()

# =========================================================
# CINEMÁTICA DEFINITIVA (CÁMARA FANTASMA + LÍMITES + VIBRACIÓN)
# =========================================================
func _cinematica_apertura_puerta() -> void:
	var foco_camara = get_node_or_null("TileMapLayers/FocoCamaraPuerta")
	var destino = foco_camara.global_position if foco_camara else puerta_central.global_position

	# 1. Congelar a Lino
	if jugador.has_method("take_control"):
		jugador.take_control(self)
	jugador.velocity = Vector2.ZERO

	# 2. Obtener la cámara real de Lino
	var cam_lino = get_viewport().get_camera_2d()

	# 3. CREAR LA CÁMARA FANTASMA TEMPORAL
	var cam_cinematica = Camera2D.new()
	
	# CLAVE 1: Usamos el centro real de la pantalla para evitar saltos si Lino está contra una pared
	cam_cinematica.global_position = cam_lino.get_screen_center_position()
	cam_cinematica.zoom = cam_lino.zoom
	
	# CLAVE 2: Heredamos los límites del mapa para que el viaje no exponga el vacío negro
	cam_cinematica.limit_left = cam_lino.limit_left
	cam_cinematica.limit_right = cam_lino.limit_right
	cam_cinematica.limit_top = cam_lino.limit_top
	cam_cinematica.limit_bottom = cam_lino.limit_bottom

	add_child(cam_cinematica)
	cam_cinematica.make_current()

	# 4. LA CINEMÁTICA
	var cinematica = create_tween()

	# Fase A: Zoom dramático hacia la puerta (Acercamiento a 1.5)
	cinematica.tween_property(cam_cinematica, "global_position", destino, 1.2).set_trans(Tween.TRANS_SINE)
	cinematica.parallel().tween_property(cam_cinematica, "zoom", Vector2(1.5, 1.5), 1.2).set_trans(Tween.TRANS_SINE)
	cinematica.tween_interval(0.2)

	# =======================================================
	# Fase B: TENSIÓN (La puerta tiembla antes de ceder)
	# =======================================================
	if is_instance_valid(puerta_central):
		var pos_original_puerta = puerta_central.position
		
		# Vibra aumentando la fuerza progresivamente
# Vibra aumentando la fuerza progresivamente por 1.2 segundos (30 iteraciones)
		for i in range(30):
			var intensidad = float(i) / 30.0
			# Subimos el rango a 4.0 para que el temblor final se sienta más fuerte
			var vibracion = Vector2(randf_range(-4.0, 4.0) * intensidad, randf_range(-4.0, 4.0) * intensidad)
			cinematica.tween_property(puerta_central, "position", pos_original_puerta + vibracion, 0.04)

		# La clavamos en su centro exacto justo para el impacto final
		cinematica.tween_property(puerta_central, "position", pos_original_puerta, 0.05)
	# =======================================================

	# Fase C: ¡PUM! Se abre la puerta de golpe + Temblor de cámara
	cinematica.tween_callback(func():
		if is_instance_valid(puerta_central):
			puerta_central.open()
			_sacudir_pantalla() 
	)

	# Fase D: Pausa dramática para asimilar el impacto
	cinematica.tween_interval(1.2)

	# Fase E: Regreso fluido al centro de pantalla de Lino (NO a su cuerpo, evitando el salto)
	cinematica.tween_property(cam_cinematica, "global_position", cam_lino.get_screen_center_position(), 0.8).set_trans(Tween.TRANS_QUAD)
	cinematica.parallel().tween_property(cam_cinematica, "zoom", cam_lino.zoom, 0.8)

	await cinematica.finished

	# 5. RESTAURAR TODO Y DESTRUIR LA CÁMARA TEMPORAL
	cam_lino.make_current() 
	cam_cinematica.queue_free() 

	if jugador.has_method("return_control"):
		jugador.return_control(self)

# --- SISTEMA DE COMBATE ---
func _al_recibir_bolita(body: Node2D) -> void:
	if not body.is_in_group("projectiles") or lino_muerto:
		return
		
	body.call_deferred("queue_free")
	
	golpes_recibidos += 1
	var porcentaje = float(golpes_recibidos) / 4.0
	porcentaje = clamp(porcentaje, 0.0, 1.0) 
	material_gris.set_shader_parameter("nivel_gris", porcentaje)
	
	if not primer_golpe_recibido and is_instance_valid(panel_pensamiento):
		primer_golpe_recibido = true
		panel_pensamiento.mostrar_pensamiento("Cada impacto me arrebata un recuerdo...\nSi dejo que la culpa me consuma, me perderé.")
	
	if golpes_recibidos >= MAX_GOLPES:
		lino_muerto = true
		hitbox_jugador.set_deferred("monitoring", false)
		hitbox_jugador.set_deferred("monitorable", false)
		jugador.defeat(false)

# --- LIMPIEZA DE ALAS (CON ILUSIÓN DE ELECCIÓN) ---
func _al_completar_jarron_izq() -> void:
	jarrones_izq_completados += 1
	if jarrones_izq_completados == 2:
		alas_limpiadas += 1
		if is_instance_valid(enemigo_1): enemigo_1.queue_free()
		if is_instance_valid(enemigo_2): enemigo_2.queue_free()
		get_tree().call_group("projectiles", "remove")
		
		if is_instance_valid(hilo_izq): 
			hilo_izq.dialogue_title = "hilo_1" if alas_limpiadas == 1 else "hilo_2"
			hilo_izq.reveal()

func _al_completar_jarron_der() -> void:
	jarrones_der_completados += 1
	if jarrones_der_completados == 2:
		alas_limpiadas += 1
		if is_instance_valid(enemigo_3): enemigo_3.queue_free()
		if is_instance_valid(enemigo_4): enemigo_4.queue_free()
		get_tree().call_group("projectiles", "remove")
		
		if is_instance_valid(hilo_der): 
			hilo_der.dialogue_title = "hilo_1" if alas_limpiadas == 1 else "hilo_2"
			hilo_der.reveal()

func _al_completar_jarron_central() -> void:
	get_tree().call_group("throwing_enemy", "remove")
	get_tree().call_group("projectiles", "remove")
	if is_instance_valid(hilo_central): hilo_central.reveal()

# --- EL GATILLO DEL PASILLO (TEXTO FLOTANTE) ---
func _on_trigger_central_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not texto_central_mostrado:
		texto_central_mostrado = true
		if is_instance_valid(panel_pensamiento):
			panel_pensamiento.mostrar_pensamiento("La culpa es ensordecedora aquí adentro...\nSolo un paso más.")
