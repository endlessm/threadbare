# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export_category("Cinemática CINE - Recursos")
@export var dialogo_boss: DialogueResource
@export var titulo_dialogo_boss: String = "boss_final"
@export var dialogo_lazaro: DialogueResource
@export var titulo_dialogo_lazaro: String = "lazaro_final"
@export var escena_outro: PackedScene
@export var nodo_vacio: Node2D

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
@onready var jarrones_boss = [
	$OnTheGround/FillingBarrel5,
	$OnTheGround/FillingBarrel6,
	$OnTheGround/FillingBarrel7
]

# 4. REFERENCIAS CINEMÁTICA NORTE
@onready var lazaro = $OnTheGround2/Lazaro
@onready var luto = $OnTheGround2/Luto
@onready var posicion_luto_final = $OnTheGround2/DetectorDialogo/PosicionJuntoALazaro

var jarrones_boss_completados: int = 0
var boss_derrotado: bool = false

@onready var bloqueo_puente = $OnTheGround/BloqueoPuente
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
	for jarron in jarrones_boss:
		if is_instance_valid(jarron): jarron.completed.connect(_al_completar_jarron_boss)

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
		for jarron in jarrones_boss:
			if is_instance_valid(jarron): jarron.queue_free()
		if is_instance_valid(enemigo_8): enemigo_8.queue_free()
		if is_instance_valid(hilo_central): hilo_central.queue_free()
		if is_instance_valid(lazaro): lazaro.queue_free()
		if is_instance_valid(luto): luto.queue_free()
		hilos_recogidos += 1
	elif is_instance_valid(hilo_central): 
		hilo_central.revealed = false
		hilo_central.tree_exited.connect(_al_recoger_hilo.bind("central"))

	_actualizar_color_ambiente()
	if hilos_recogidos >= 2 and is_instance_valid(puerta_central): puerta_central.open()
	if hilos_recogidos >= 3 and is_instance_valid(puerta_salida): puerta_salida.open()

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

func _al_recoger_hilo(id_hilo: String = "") -> void:
	if not is_inside_tree(): return
	
	match id_hilo:
		"izq": estado_hilo_izq = true
		"der": estado_hilo_der = true
		"central": estado_hilo_central = true
		
	hilos_recogidos += 1
	_actualizar_color_ambiente()
	
	if hilos_recogidos == 2 and id_hilo != "central":
		_cinematica_apertura_puerta()
			
	if id_hilo == "central":
		_cinematica_final_climax()

# =========================================================
# CINEMÁTICA CLÍMAX — DIRECCIÓN DE ARTE PULIDA
# =========================================================
func _cinematica_final_climax() -> void:

	var spr_lazaro: AnimatedSprite2D = null
	var spr_luto: AnimatedSprite2D = null
	var tween_lazaro_vivo: Tween = null
	var pos_lazaro_y_base: float = 0.0

	# ──── 1. Congelar a Lino ─────────────────────────────────────────────────
	if jugador.has_method("take_control"):
		jugador.take_control(self)
	jugador.velocity = Vector2.ZERO

	# ──── 2. Diálogo del Boss ────────────────────────────────────────────────
	if dialogo_boss and is_instance_valid(enemigo_8):
		DialogueManager.show_dialogue_balloon(dialogo_boss, titulo_dialogo_boss)
		await DialogueManager.dialogue_ended

		# ──── 3. Agonía del Boss ─────────────────────────────────────────────
		var spr_boss: Node = enemigo_8.get_node_or_null("AnimatedSprite2D")
		if not is_instance_valid(spr_boss):
			for h in enemigo_8.get_children():
				if h is AnimatedSprite2D:
					spr_boss = h
					break

		var pos_boss = enemigo_8.position
		var vibra = create_tween()
		for i in range(60):
			vibra.tween_property(enemigo_8, "position",
				pos_boss + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)), 0.05)
		vibra.tween_property(enemigo_8, "position", pos_boss, 0.05)

		await get_tree().create_timer(0.3).timeout

		if is_instance_valid(spr_boss) and spr_boss.material != null:
			spr_boss.material = null
		if is_instance_valid(enemigo_8) and enemigo_8.material != null:
			enemigo_8.material = null

		var fade_boss = create_tween().set_parallel(true)
		if is_instance_valid(enemigo_8):
			fade_boss.tween_property(enemigo_8, "modulate:a", 0.0, 2.7)
		if is_instance_valid(spr_boss):
			fade_boss.tween_property(spr_boss, "modulate:a", 0.0, 2.7)
		await fade_boss.finished
		if is_instance_valid(enemigo_8): enemigo_8.queue_free()

	# ──── 4. FADE 1: BLANCO (Epifanía y conexión) ────────────────────────────
	var canvas_fade = CanvasLayer.new()
	canvas_fade.layer = 100
	var rect_fade = ColorRect.new()
	rect_fade.color = Color(1.0, 1.0, 1.0, 0.0) # Transparente a Blanco
	rect_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_fade.add_child(rect_fade)
	add_child(canvas_fade)

	# Transición mucho más lenta y curva suave
	var tween = create_tween()
	tween.tween_property(rect_fade, "color:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# ──── 5. Cámara: Acercamiento íntimo en Lázaro ───────────────────────────
	var cam_lino = get_viewport().get_camera_2d()
	var cam_cine = Camera2D.new()

	if is_instance_valid(lazaro):
		cam_cine.global_position = lazaro.global_position
		cam_cine.zoom = Vector2(1.5, 1.5) # Restaurado al acercamiento que pediste
	add_child(cam_cine)
	cam_cine.make_current()

	# Preparar personajes
	if is_instance_valid(lazaro) and lazaro is AnimatedSprite2D:
		spr_lazaro = lazaro as AnimatedSprite2D
		pos_lazaro_y_base = spr_lazaro.position.y

		spr_lazaro.stop()
		spr_lazaro.play("idle")

		tween_lazaro_vivo = create_tween().set_loops()
		tween_lazaro_vivo.tween_property(spr_lazaro, "position:y", pos_lazaro_y_base - 5.0, 1.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_lazaro_vivo.tween_property(spr_lazaro, "position:y", pos_lazaro_y_base, 1.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if is_instance_valid(luto):
		spr_luto = luto.get_node_or_null("AnimatedSprite2D")

	# ──── 6. Aparece el Recuerdo ─────────────────────────────────────────────
	tween = create_tween()
	tween.tween_property(rect_fade, "color:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# ──── 7. Luto camina ─────────────────────────────────────────────────────
	if is_instance_valid(luto) and is_instance_valid(spr_luto) and is_instance_valid(posicion_luto_final):
		var destino = posicion_luto_final.global_position

		spr_luto.flip_h = (destino.x - luto.global_position.x) < 0
		spr_luto.stop()
		spr_luto.play("walk")

		var tween_luto = create_tween()
		tween_luto.tween_property(luto, "global_position", destino, 2.5).set_trans(Tween.TRANS_SINE)
		await tween_luto.finished

		if is_instance_valid(spr_luto):
			spr_luto.stop()
			spr_luto.play("idle")
			if is_instance_valid(lazaro):
				spr_luto.flip_h = (lazaro.global_position.x - luto.global_position.x) < 0

		if is_instance_valid(spr_lazaro) and is_instance_valid(luto):
			spr_lazaro.flip_h = (luto.global_position.x - lazaro.global_position.x) < 0

	# ──── 8. Diálogo de Lázaro ───────────────────────────────────────────────
	if dialogo_lazaro:
		DialogueManager.show_dialogue_balloon(dialogo_lazaro, titulo_dialogo_lazaro)
		await DialogueManager.dialogue_ended

	# ──── 9. Desvanecimiento en paz ──────────────────────────────────────────
	if is_instance_valid(tween_lazaro_vivo):
		tween_lazaro_vivo.kill()
	if is_instance_valid(spr_lazaro):
		spr_lazaro.position.y = pos_lazaro_y_base

	if is_instance_valid(lazaro):
		lazaro.use_parent_material = false
		lazaro.material = null
	if is_instance_valid(luto):
		luto.use_parent_material = false
		luto.material = null
		if is_instance_valid(spr_luto):
			spr_luto.use_parent_material = false
			spr_luto.material = null

	var tween_paz = create_tween().set_parallel(true)
	if is_instance_valid(lazaro):
		tween_paz.tween_property(lazaro, "modulate:a", 0.0, 3.0)
	if is_instance_valid(luto):
		tween_paz.tween_property(luto, "modulate:a", 0.0, 3.0)
		if is_instance_valid(spr_luto):
			tween_paz.tween_property(spr_luto, "modulate:a", 0.0, 3.0)
	await tween_paz.finished

	if is_instance_valid(lazaro): lazaro.queue_free()
	if is_instance_valid(luto):   luto.queue_free()

	# ──── 10. FADE 2: NEGRO (Vuelta a la cruda realidad) ─────────────────────
	# Cambiamos el color de fondo a negro transparente, luego lo oscurecemos
	rect_fade.color = Color(0, 0, 0, 0) 
	tween = create_tween()
	tween.tween_property(rect_fade, "color:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	cam_lino.make_current()
	cam_cine.queue_free()

	# ──── 11. Escape del Vacío y Zoom Out ────────────────────────────────────
	if is_instance_valid(particulas_perdon): particulas_perdon.emitting = true
	_sacudir_pantalla()
	if is_instance_valid(puerta_salida): puerta_salida.open()

	if is_instance_valid(nodo_vacio):
		var path = nodo_vacio.get_node_or_null("PathWalkBehavior")
		if is_instance_valid(path) and path.get("speeds"):
			path.speeds = path.speeds.duplicate()
			path.speeds.walk_speed = 4500.0
			path.speeds.run_speed = 4500.0

	tween = create_tween()
	# Un poco más rápido para dar la sensación de urgencia al despertar
	tween.tween_property(rect_fade, "color:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	if is_instance_valid(puerta_salida):
		sprite_jugador.play("walk")
		var escape = create_tween().set_parallel(true)
		escape.tween_property(jugador, "global_position", puerta_salida.global_position, 3.5)
		escape.tween_property(cam_lino, "zoom", cam_lino.zoom * 0.65, 3.5).set_trans(Tween.TRANS_SINE)
		await escape.finished

		# ──── 12. FADE 3: BLANCO (El pase a la luz del Outro) ────────────────
		rect_fade.color = Color(1, 1, 1, 0)
		var tween_final = create_tween()
		tween_final.tween_property(rect_fade, "color:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween_final.finished

		if escena_outro != null:
			get_tree().change_scene_to_packed(escena_outro)
		else:
			push_error("¡Arrastra el OUTRO en el inspector!")	

# =========================================================
# FUNCIONES AUXILIARES RESTANTES
# =========================================================
func _cinematica_apertura_puerta() -> void:
	var foco_camara = get_node_or_null("TileMapLayers/FocoCamaraPuerta")
	var destino = foco_camara.global_position if foco_camara else puerta_central.global_position

	if jugador.has_method("take_control"): jugador.take_control(self)
	jugador.velocity = Vector2.ZERO

	var cam_lino = get_viewport().get_camera_2d()
	var cam_cinematica = Camera2D.new()
	cam_cinematica.global_position = cam_lino.get_screen_center_position()
	cam_cinematica.zoom = cam_lino.zoom
	cam_cinematica.limit_left = cam_lino.limit_left
	cam_cinematica.limit_right = cam_lino.limit_right
	cam_cinematica.limit_top = cam_lino.limit_top
	cam_cinematica.limit_bottom = cam_lino.limit_bottom

	add_child(cam_cinematica)
	cam_cinematica.make_current()

	var cinematica = create_tween()
	cinematica.tween_property(cam_cinematica, "global_position", destino, 1.2).set_trans(Tween.TRANS_SINE)
	cinematica.parallel().tween_property(cam_cinematica, "zoom", Vector2(1.5, 1.5), 1.2).set_trans(Tween.TRANS_SINE)
	cinematica.tween_interval(0.2)

	if is_instance_valid(puerta_central):
		var pos_original_puerta = puerta_central.position
		for i in range(30):
			var intensidad = float(i) / 30.0
			var vibracion = Vector2(randf_range(-4.0, 4.0) * intensidad, randf_range(-4.0, 4.0) * intensidad)
			cinematica.tween_property(puerta_central, "position", pos_original_puerta + vibracion, 0.04)
		cinematica.tween_property(puerta_central, "position", pos_original_puerta, 0.05)

	cinematica.tween_callback(func():
		if is_instance_valid(puerta_central):
			puerta_central.open()
			_sacudir_pantalla() 
	)

	cinematica.tween_interval(1.2)
	cinematica.tween_property(cam_cinematica, "global_position", cam_lino.get_screen_center_position(), 0.8).set_trans(Tween.TRANS_QUAD)
	cinematica.parallel().tween_property(cam_cinematica, "zoom", cam_lino.zoom, 0.8)

	await cinematica.finished

	cam_lino.make_current() 
	cam_cinematica.queue_free() 

	if jugador.has_method("return_control"):
		jugador.return_control(self)

func _al_recibir_bolita(body: Node2D) -> void:
	if not body.is_in_group("projectiles") or lino_muerto: return
	body.call_deferred("queue_free")
	
	golpes_recibidos += 1
	var porcentaje = float(golpes_recibidos) / 4.0
	porcentaje = clamp(porcentaje, 0.0, 1.0) 
	material_gris.set_shader_parameter("nivel_gris", porcentaje)
	
	if not primer_golpe_recibido and is_instance_valid(panel_pensamiento):
		primer_golpe_recibido = true
		panel_pensamiento.mostrar_pensamiento("Cada golpe… me hace pensar en Manchitas...\nComo si lo estuviera perdiendo otra vez...")
	
	if golpes_recibidos >= MAX_GOLPES:
		lino_muerto = true
		hitbox_jugador.set_deferred("monitoring", false)
		hitbox_jugador.set_deferred("monitorable", false)
		jugador.defeat(false)

func _al_completar_jarron_izq() -> void:
	jarrones_izq_completados += 1
	if jarrones_izq_completados == 2:
		alas_limpiadas += 1
		if is_instance_valid(enemigo_1): enemigo_1.queue_free()
		if is_instance_valid(enemigo_2): enemigo_2.queue_free()
		get_tree().call_group("projectiles", "remove")
		
		if is_instance_valid(panel_pensamiento):
			var frases = ["La ira se desvanece...", "Aún tengo control sobre esto.", "Un peso menos."]
			panel_pensamiento.mostrar_pensamiento(frases.pick_random())
			
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
		
		if is_instance_valid(panel_pensamiento):
			var frases = ["No me dejaré arrastrar.", "Respiro de nuevo.", "Paso a paso, la culpa cede."]
			panel_pensamiento.mostrar_pensamiento(frases.pick_random())
		
		if is_instance_valid(hilo_der): 
			hilo_der.dialogue_title = "hilo_1" if alas_limpiadas == 1 else "hilo_2"
			hilo_der.reveal()

func _al_completar_jarron_boss() -> void:
	if boss_derrotado: return

	jarrones_boss_completados += 1
	if jarrones_boss_completados < 3: return

	boss_derrotado = true
	get_tree().call_group("projectiles", "remove")
	
	if is_instance_valid(enemigo_8):
		enemigo_8.process_mode = Node.PROCESS_MODE_DISABLED
		
	_sacudir_pantalla()

	if is_instance_valid(panel_pensamiento):
		panel_pensamiento.mostrar_pensamiento("Por fin... el telar recobra su calma.")
		
	if is_instance_valid(bloqueo_puente):
		bloqueo_puente.queue_free()
		
	if is_instance_valid(hilo_central):
		hilo_central.reveal()

func _on_trigger_central_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not texto_central_mostrado:
		texto_central_mostrado = true
		if is_instance_valid(panel_pensamiento):
			panel_pensamiento.mostrar_pensamiento("La culpa es ensordecedora aquí adentro...\nSolo un paso más.")
