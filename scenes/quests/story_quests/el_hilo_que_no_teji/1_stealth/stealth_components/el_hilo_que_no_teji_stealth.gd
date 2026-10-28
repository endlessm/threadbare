# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Primer nivel: Lino recoge tres hilos esquivando sombras y cruza el puente.

const DIALOGO_STEALTH = preload("uid://cut4yag2eux0s")
const SIGUIENTE_NIVEL: String = "uid://ds04vtvl5lrkt"
const HILOS: Array[String] = ["CollectibleItem", "CollectibleItem2", "CollectibleItem3"]
const HILOS_PARA_TERMINAR: int = 3
const TIEMPO_MAXIMO_REVIVIR: float = 4.0

const CAPAS := "TileMapLayers/"
const RUTA_PUENTE_NORMAL := CAPAS + "PuenteNormal"
const RUTA_PUENTE_ROTO := CAPAS + "PuenteRoto"
const RUTA_BLOQUEO_PUENTE := CAPAS + "BloqueoPuente"
const RUTA_ROCAS_1 := CAPAS + "RocasBloqueoHilo1"
const RUTA_ROCAS_2 := CAPAS + "RocasBloqueoHilo2"
const RUTA_ROCAS_3 := CAPAS + "RocasBloqueoHilo3"
const RUTA_FOCO_ROCAS_2 := CAPAS + "FocoCamaraRocas2"
const NOMBRE_LUTO := "Luto-Guard"
const ROCAS_ESCONDIDAS := Vector2(9999, 9999)

const INTERVALO_LADRIDO := Vector2(100.0, 140.0)
const PUNTO_LUTO := Vector2(620, -4500)

const ZONA_PUENTE_CENTRO := Vector2(608, -4150)
const ZONA_PUENTE_TAMANO := Vector2(190, 60)

const DISTANCIA_LUTO_A_LINO: float = 250.0
const PAUSA_ANTES_DE_HUIR_LUTO: float = 0.8
const VELOCIDAD_ANIMACION_HUIDA_LUTO: float = 2.5
const DISTANCIA_HUIDA_LUTO: float = 420.0
const DURACION_HUIDA_LUTO: float = 2.4
const DURACION_DESVANECER_LUTO: float = 0.8
const LADRIDO_DURANTE_HUIDA: float = 1.2
const MARGEN_SOBRE_LIMITE_CAMARA: float = 80.0
const Z_INDEX_DE_LUTO: int = 11

const ZOOM_SOBRE_LAS_ROCAS := Vector2(1.4, 1.4)
const DURACION_IR_A_LAS_ROCAS: float = 1.2
const PAUSA_ANTES_DE_DESINTEGRAR: float = 0.3
const PAUSA_TRAS_DESINTEGRAR: float = 0.8
const DURACION_VOLVER_CON_LINO: float = 0.8
const SACUDIDAS_AL_DESINTEGRAR: int = 24
const DURACION_SACUDIDA: float = 0.05
const BRILLO_DEL_DESTELLO := Color(2.0, 2.0, 2.0, 1.0)
const ELEVACION_AL_DESVANECER: float = 15.0
const DURACION_DESVANECER_OBJETO: float = 0.6
const DURACION_APARECER_CARTEL: float = 0.8

const FUENTE_ARBOL: int = 7
const ATLAS_TRONCO := Vector2i(2, 3)
const TAPON_DIAGONAL: float = 0.7

# static: el progreso sobrevive a la recarga del nivel cuando Lino muere
static var hilos_totales: int = 0
static var hilos_tomados: Array[bool] = [false, false, false]

var nivel_apagandose: bool = false
var temporizador_ladrido: Timer

@onready var particulas_doradas: GPUParticles2D = $TileMapLayers/Tree/ParticulasDoradas
@onready var flecha: Sprite2D = $TileMapLayers/Tree/Flecha


func _ready() -> void:
	ElHiloQueNoTejiIdiomas.registrar()
	if ElHiloQueNoTejiState.es_partida_nueva_para("stealth"):
		hilos_totales = 0
		hilos_tomados = [false, false, false]

	GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_B, false)
	nivel_apagandose = false
	tree_exiting.connect(_al_descargar_nivel)

	_mostrar_rocas_hilo_3(hilos_tomados[2])

	if hilos_tomados[2]:
		_abrir_puente()
	else:
		var puente_normal := get_node_or_null(RUTA_PUENTE_NORMAL) as TileMapLayer
		if puente_normal:
			puente_normal.visible = false
			puente_normal.process_mode = Node.PROCESS_MODE_DISABLED

	if hilos_tomados[0]:
		_liberar_nodo(HILOS[0])
		_liberar_nodo(RUTA_ROCAS_1)

	if hilos_tomados[1]:
		_liberar_nodo(HILOS[1])
		_liberar_nodo(RUTA_ROCAS_2)
		_liberar_nodo("Sign")

	if hilos_tomados[2]:
		_liberar_nodo(HILOS[2])

	verificar_progreso()
	_preparar_ladridos()
	_bloquear_salto_dialogo_inicial()
	_crear_zona_puente_luto()
	_tapar_huecos_diagonales_de_arboles()
	_preparar_pesadilla_y_fantasma()
	_mostrar_cartel_de_shift(hilos_tomados[1])
	var reaparicion := ReaparicionEnHilo.new()
	if GameState.scene.intro_dialogue_shown:
		reaparicion.termino.connect(_ladrar_hacia_lo_siguiente)
	add_child(reaparicion)


func _liberar_nodo(ruta: String) -> void:
	var nodo := get_node_or_null(ruta)
	if nodo:
		nodo.queue_free()


func verificar_progreso() -> void:
	if hilos_totales >= HILOS_PARA_TERMINAR and flecha:
		flecha.visible = true


func _bloquear_salto_dialogo_inicial() -> void:
	if GameState.scene.intro_dialogue_shown:
		return
	var lino := get_tree().get_first_node_in_group("player") as Player
	var sprite: AnimatedSprite2D = lino.get_node("%PlayerSprite")
	var animation_player: AnimationPlayer = lino.get_node("AnimationPlayer")

	lino.take_control(self)
	# El AnimationPlayer del jugador fuerza "idle" en cada cuadro: se pausa.
	animation_player.pause()
	animation_player.set_process(false)

	sprite.play(&"revive")
	var limite := Time.get_ticks_msec() + int(TIEMPO_MAXIMO_REVIVIR * 1000)
	while sprite.is_playing() and sprite.animation == &"revive" and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	sprite.play(&"c_confused")

	var bloqueo := BloqueoSaltoDialogo.new()
	add_child(bloqueo)
	$Cinematic.start()
	await $Cinematic.cinematic_finished
	bloqueo.queue_free()

	animation_player.set_process(true)
	animation_player.play(&"idle")
	lino.return_control(self)
	_ladrar_hacia_lo_siguiente()


func _preparar_ladridos() -> void:
	temporizador_ladrido = Timer.new()
	temporizador_ladrido.one_shot = true
	temporizador_ladrido.wait_time = randf_range(INTERVALO_LADRIDO.x, INTERVALO_LADRIDO.y)
	temporizador_ladrido.timeout.connect(_ladrar_hacia_lo_siguiente)
	add_child(temporizador_ladrido)
	if GameState.scene.intro_dialogue_shown:
		temporizador_ladrido.start()


func _ladrar_hacia_lo_siguiente() -> void:
	if not is_inside_tree() or nivel_apagandose:
		return
	temporizador_ladrido.start(randf_range(INTERVALO_LADRIDO.x, INTERVALO_LADRIDO.y))

	var lino := get_tree().get_first_node_in_group("player") as Node2D
	if not lino:
		return
	if hilos_totales >= HILOS_PARA_TERMINAR:
		_ladrar_en(PUNTO_LUTO)
		return
	var mas_cercano := _hilo_mas_cercano_a(lino)
	if mas_cercano:
		_ladrar_en(mas_cercano.global_position)
	else:
		_ladrar_en(PUNTO_LUTO)


func _hilo_mas_cercano_a(lino: Node2D) -> Node2D:
	var mas_cercano: Node2D = null
	for nombre in HILOS:
		var hilo := get_node_or_null(nombre) as Node2D
		if not hilo or not hilo.is_inside_tree() or hilo.is_queued_for_deletion():
			continue
		var distancia := hilo.global_position.distance_to(lino.global_position)
		if (
			not mas_cercano
			or distancia < mas_cercano.global_position.distance_to(lino.global_position)
		):
			mas_cercano = hilo
	return mas_cercano


func _ladrar_desde(nodo: Node2D) -> void:
	if is_instance_valid(nodo):
		Ladrido.sonar(self, nodo.global_position, 1)


func _ladrar_en(posicion: Vector2) -> void:
	Ladrido.sonar(self, posicion)


func _al_descargar_nivel() -> void:
	nivel_apagandose = true


func _registrar_hilo(indice: int) -> bool:
	if nivel_apagandose or hilos_tomados[indice]:
		return false
	hilos_tomados[indice] = true
	hilos_totales += 1
	verificar_progreso()
	return true


func _on_collectible_item_tree_exited() -> void:
	if _registrar_hilo(0):
		await _romper_rocas_sin_camara(RUTA_ROCAS_1)
		_ladrar_hacia_lo_siguiente()


func _on_collectible_item_2_tree_exited() -> void:
	if _registrar_hilo(1):
		await _romper_rocas(RUTA_ROCAS_2, RUTA_FOCO_ROCAS_2, get_node_or_null("Sign") as Node2D)
		_mostrar_cartel_de_shift(true)
		_ladrar_hacia_lo_siguiente()


func _romper_rocas_sin_camara(ruta_rocas: String) -> void:
	var rocas := get_node_or_null(ruta_rocas) as TileMapLayer
	if not rocas:
		return
	var desintegracion := create_tween()
	_desintegrar(desintegracion, rocas)
	await desintegracion.finished


func _romper_rocas(ruta_rocas: String, ruta_foco: String, acompanante: Node2D = null) -> void:
	var rocas := get_node_or_null(ruta_rocas) as TileMapLayer
	var lino := get_tree().get_first_node_in_group("player") as Player
	if not rocas or not lino:
		return
	var foco := get_node_or_null(ruta_foco) as Node2D

	lino.take_control(self)
	lino.velocity = Vector2.ZERO
	var guardias := get_node_or_null("EnemyGuards")
	if guardias:
		guardias.process_mode = Node.PROCESS_MODE_DISABLED

	var camara := get_viewport().get_camera_2d()
	var zoom_original := camara.zoom
	var suavizado_original := camara.position_smoothing_enabled
	# con el suavizado la cámara se queda atrás y el tween no llega al foco
	camara.position_smoothing_enabled = false

	var cinematica := create_tween()
	var destino_camara := foco.global_position if foco else _centro_de(rocas)
	(
		cinematica
		. tween_property(camara, "global_position", destino_camara, DURACION_IR_A_LAS_ROCAS)
		. set_trans(Tween.TRANS_SINE)
	)
	cinematica.parallel().tween_property(
		camara, "zoom", ZOOM_SOBRE_LAS_ROCAS, DURACION_IR_A_LAS_ROCAS
	)
	cinematica.chain().tween_interval(PAUSA_ANTES_DE_DESINTEGRAR)
	if acompanante:
		cinematica.tween_callback(func(): _desintegrar(create_tween(), acompanante))
	_desintegrar(cinematica, rocas)
	cinematica.tween_interval(PAUSA_TRAS_DESINTEGRAR)
	(
		cinematica
		. tween_property(camara, "global_position", lino.global_position, DURACION_VOLVER_CON_LINO)
		. set_trans(Tween.TRANS_QUAD)
	)
	cinematica.parallel().tween_property(camara, "zoom", zoom_original, DURACION_VOLVER_CON_LINO)
	await cinematica.finished

	camara.position_smoothing_enabled = suavizado_original
	camara.global_position = lino.global_position
	if is_instance_valid(guardias):
		guardias.process_mode = Node.PROCESS_MODE_INHERIT
	lino.return_control(self)


func _desintegrar(animacion: Tween, objeto: Node2D) -> void:
	var pos_original := objeto.position
	for i in SACUDIDAS_AL_DESINTEGRAR:
		var intensidad := float(i) / SACUDIDAS_AL_DESINTEGRAR
		var fuerza_x := randf_range(-1.0, 1.0) + randf_range(-4.0, 4.0) * intensidad
		var fuerza_y := randf_range(-1.0, 1.0) + randf_range(-2.0, 2.0) * intensidad
		animacion.tween_property(
			objeto, "position", pos_original + Vector2(fuerza_x, fuerza_y), DURACION_SACUDIDA
		)

	# Los shaders de saturación ignoran el modulate; sin ellos se ven el
	# destello y el desvanecimiento.
	animacion.tween_callback(
		func():
			if is_instance_valid(objeto):
				_quitar_materiales(objeto)
				objeto.modulate = BRILLO_DEL_DESTELLO
	)
	(
		animacion
		. tween_property(
			objeto,
			"position",
			pos_original + Vector2(0, -ELEVACION_AL_DESVANECER),
			DURACION_DESVANECER_OBJETO
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	animacion.parallel().tween_property(
		objeto, "modulate", Color(1.0, 1.0, 1.0, 0.0), DURACION_DESVANECER_OBJETO
	)
	animacion.tween_callback(objeto.queue_free)


func _quitar_materiales(nodo: Node) -> void:
	if nodo is CanvasItem:
		nodo.material = null
	for hijo in nodo.get_children():
		_quitar_materiales(hijo)


func _centro_de(capa: TileMapLayer) -> Vector2:
	var celdas := capa.get_used_cells()
	if celdas.is_empty():
		return capa.global_position
	var suma := Vector2.ZERO
	for celda in celdas:
		suma += capa.to_global(capa.map_to_local(celda))
	return suma / celdas.size()


func _on_collectible_item_3_tree_exited() -> void:
	if _registrar_hilo(2):
		_mostrar_rocas_hilo_3(true)
		_abrir_puente()
		_ladrar_hacia_lo_siguiente()


func _mostrar_rocas_hilo_3(mostrar: bool) -> void:
	var rocas_3 := get_node_or_null(RUTA_ROCAS_3) as TileMapLayer
	if not rocas_3:
		return
	# ocultar no apaga las colisiones del TileMapLayer: por eso se manda lejos
	rocas_3.visible = mostrar
	rocas_3.position = Vector2.ZERO if mostrar else ROCAS_ESCONDIDAS


func _abrir_puente() -> void:
	_liberar_nodo(RUTA_PUENTE_ROTO)
	_liberar_nodo(RUTA_BLOQUEO_PUENTE)

	var puente_normal := get_node_or_null(RUTA_PUENTE_NORMAL) as TileMapLayer
	if puente_normal:
		puente_normal.visible = true
		puente_normal.process_mode = Node.PROCESS_MODE_INHERIT


func _on_zona_climax_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if hilos_totales >= HILOS_PARA_TERMINAR:
			body.velocity = Vector2.ZERO
			body.take_control(self)
			$ZonaClimax.set_deferred("monitoring", false)

			if has_node("EnemyGuards"):
				$EnemyGuards.queue_free()

			particulas_doradas.emitting = true
			if flecha:
				flecha.visible = false

			add_child(BloqueoSaltoDialogo.new())
			DialogueManager.show_dialogue_balloon(DIALOGO_STEALTH, "arbol_climax")
			await DialogueManager.dialogue_ended
			SceneSwitcher.change_to_file_with_transition(SIGUIENTE_NIVEL)


func _preparar_pesadilla_y_fantasma() -> void:
	var pesadilla := Pesadilla.new()
	var luto := find_child(NOMBRE_LUTO, true, false)
	if luto:
		pesadilla.inofensivos = [luto]
		luto.add_child(EfectoFantasma.new())
	add_child(pesadilla)


func _mostrar_cartel_de_shift(mostrar: bool) -> void:
	var cartel := get_node_or_null("CartelShift") as Node2D
	if not cartel:
		return
	var choque := cartel.get_node_or_null("Collider/CollisionShape2D") as CollisionShape2D
	if choque:
		choque.set_deferred("disabled", not mostrar)
	if not mostrar:
		cartel.hide()
	elif not cartel.visible:
		cartel.modulate.a = 0.0
		cartel.show()
		create_tween().tween_property(cartel, "modulate:a", 1.0, DURACION_APARECER_CARTEL)


func _crear_zona_puente_luto() -> void:
	var zona := Area2D.new()
	zona.collision_mask = $ZonaClimax.collision_mask
	var forma := CollisionShape2D.new()
	var rectangulo := RectangleShape2D.new()
	rectangulo.size = ZONA_PUENTE_TAMANO
	forma.shape = rectangulo
	zona.add_child(forma)
	add_child(zona)
	zona.global_position = ZONA_PUENTE_CENTRO
	zona.body_entered.connect(_al_cruzar_puente_luto.bind(zona))


func _al_cruzar_puente_luto(body: Node2D, zona: Area2D) -> void:
	if not body.is_in_group("player") or not hilos_tomados[2]:
		return
	zona.queue_free()
	temporizador_ladrido.stop()
	# Se sale de la señal de física antes de cambiar a Luto de padre.
	await get_tree().process_frame

	var luto := find_child(NOMBRE_LUTO, true, false) as Node2D
	if not luto:
		_ladrar_en(PUNTO_LUTO)
		return
	var sprite := luto.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	# EnemyGuards se borra en el diálogo del clímax; Luto sale de ahí para seguir corriendo.
	luto.reparent(self)
	luto.z_index = Z_INDEX_DE_LUTO

	# Luto patrulla en el borde de la cámara y no se ve: se lo pone delante de Lino.
	luto.global_position = Vector2(
		ZONA_PUENTE_CENTRO.x, body.global_position.y - DISTANCIA_LUTO_A_LINO
	)

	luto.process_mode = Node.PROCESS_MODE_DISABLED
	if sprite:
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		sprite.flip_h = body.global_position.x < luto.global_position.x
		sprite.play(&"bark")
	Ladrido.sonar(self, luto.global_position, 1)
	await get_tree().create_timer(PAUSA_ANTES_DE_HUIR_LUTO).timeout
	if not is_instance_valid(luto):
		return

	if sprite:
		sprite.play(&"walk")
		sprite.speed_scale = VELOCIDAD_ANIMACION_HUIDA_LUTO
	var camara := get_viewport().get_camera_2d()
	var destino_y := luto.global_position.y - DISTANCIA_HUIDA_LUTO
	if camara:
		destino_y = camara.limit_top - MARGEN_SOBRE_LIMITE_CAMARA
	var huida := create_tween()
	huida.tween_property(luto, "global_position:y", destino_y, DURACION_HUIDA_LUTO)
	huida.parallel().tween_property(luto, "modulate:a", 0.0, DURACION_DESVANECER_LUTO).set_delay(
		DURACION_HUIDA_LUTO - DURACION_DESVANECER_LUTO
	)
	huida.parallel().tween_callback(_ladrar_desde.bind(luto)).set_delay(LADRIDO_DURANTE_HUIDA)
	huida.tween_callback(luto.queue_free)


func _tapar_huecos_diagonales_de_arboles() -> void:
	var troncos := get_node_or_null("TileMapLayers/SmallTreesBase") as TileMapLayer
	if not troncos:
		return

	var celdas_tronco: Dictionary = {}
	for celda in troncos.get_used_cells():
		if (
			troncos.get_cell_source_id(celda) == FUENTE_ARBOL
			and troncos.get_cell_atlas_coords(celda) == ATLAS_TRONCO
		):
			celdas_tronco[celda] = true

	var tapones := StaticBody2D.new()
	tapones.collision_layer = troncos.tile_set.get_physics_layer_collision_layer(0)
	tapones.collision_mask = 0
	var lado: float = troncos.tile_set.tile_size.x * troncos.global_scale.x * TAPON_DIAGONAL

	for celda in celdas_tronco:
		for dx in [-1, 1]:
			var diagonal: Vector2i = celda + Vector2i(dx, 1)
			var hay_hueco: bool = (
				celdas_tronco.has(diagonal)
				and not celdas_tronco.has(celda + Vector2i(0, 1))
				and not celdas_tronco.has(celda + Vector2i(dx, 0))
			)
			if not hay_hueco:
				continue
			var forma := CollisionShape2D.new()
			var cuadrado := RectangleShape2D.new()
			cuadrado.size = Vector2(lado, lado)
			forma.shape = cuadrado
			forma.position = (
				(
					troncos.to_global(troncos.map_to_local(celda))
					+ troncos.to_global(troncos.map_to_local(diagonal))
				)
				/ 2.0
			)
			tapones.add_child(forma)

	add_child(tapones)
