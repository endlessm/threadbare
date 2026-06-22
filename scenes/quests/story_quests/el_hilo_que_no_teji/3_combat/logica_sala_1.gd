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
		if is_instance_valid(puerta_central):
			puerta_central.open()
			
	elif hilos_recogidos == 3:
		if is_instance_valid(particulas_perdon):
			particulas_perdon.emitting = true
		_sacudir_pantalla()
		
		if is_instance_valid(puerta_salida):
			puerta_salida.open()

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
