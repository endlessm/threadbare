# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## El vacío devora la isla que Lino deja al cruzar un puente.

# 0 es State.IDLE del enum de VoidSpreadingEnemy: el vacío quieto, esperando
const ESTADO_RONDA: int = 0
const RUTA_EN_EL_SUELO: String = "OnTheGround"
const RUTA_JUGADOR: String = "OnTheGround/Player"
const RUTA_VACIO: String = "OnTheGround/VoidSpreadingEnemy"
const RUTA_SUELO: String = "TileMapLayers/Suelo"
const RUTA_PRIMER_PUENTE: String = "TileMapLayers/PuenteIsla1a2"
const RUTA_PUENTE: String = "TileMapLayers/Puente%d"
const NOMBRE_DE_LUTO: StringName = &"Luto"
const PREFIJO_DE_PUZZLE: String = "Puzzle_"
const VECINAS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const PAUSA_ENTRE_POLVOS: float = 0.12
const DISTANCIA_DE_DISPARO: float = 230.0
const ZOOM_AL_ALEJAR: float = 0.6
const TIEMPO_CAMARA: float = 0.9
const VELOCIDAD_AL_DEVORAR: float = 1100.0
const TIEMPO_CRECER: float = 0.8
const PARTE_DEL_PUENTE_PARA_CALMARSE: float = 0.8
const RADIO_DE_UNA_NUBE: float = 144.0
const FURIA_POR_NUBE: float = 200.0
## Cada cuánto se sueltan las nubes de la furia y cuántas puede haber vivas a la vez.
const PAUSA_ENTRE_NUBES_DE_FURIA: float = 0.05
const MAXIMO_DE_NUBES_VIVAS: int = 60
const TIEMPO_MINIMO: float = 1.6
const PARTE_DEL_RADIO_PARA_LA_VUELTA: float = 0.55
const RADIO_AL_DEVORAR: float = 230.0
const TIEMPO_RESTOS: float = 0.7
const VIAJES_MAXIMOS: int = 40
const TIEMPO_CRUZAR_PUENTE: float = 1.1
const PAUSA_FINAL: float = 0.5
const TIEMPO_SIN_CAPTURA: float = 2.0
const CELDAS_MAXIMAS: int = 4000
const VELOCIDAD_POR_ISLA: Array[float] = [110.0, 135.0, 160.0]
const VENTAJA_POR_ISLA: Array[float] = [0.0, 0.0, 6.0]
const FRENO_POR_MUERTE: float = 0.06
const VELOCIDAD_MINIMA: float = 0.6
const CELDAS_MAXIMAS_DE_LLEGADA: int = 20000
const DISTANCIA_PUENTE_A_ISLA: float = 96.0
const DISTANCIA_DE_LLEGADA: float = 4.0
const MAXIMA_DISTANCIA_A_UNA_CELDA: float = 6.0
const MARGEN_DE_SALIDA_DEL_PUENTE: float = 32.0

# static: las islas ya devoradas sobreviven a la recarga; logica_nivel_2 las ajusta
static var hechas: Array[bool] = [false, false]

var nivel: Node2D
var jugador: Node2D
var vacio: Node2D
var suelo: TileMapLayer
var ruta: Path2D
var cruces: Array[Dictionary] = []
var ocupada: bool = false
var velocidades_del_vacio: CharacterSpeeds
var vacio_esperando: bool = false
var furia: float = 0.0
var proximo_polvo: float = 0.0
var proxima_nube_de_furia: float = 0.0


func _ready() -> void:
	nivel = get_parent() as Node2D
	jugador = nivel.get_node_or_null(RUTA_JUGADOR) as Node2D
	vacio = nivel.get_node_or_null(RUTA_VACIO) as Node2D
	suelo = nivel.get_node_or_null(RUTA_SUELO) as TileMapLayer
	if not jugador or not vacio or not suelo:
		set_process(false)
		return
	ruta = vacio.get("idle_patrol_path") as Path2D
	if not ruta:
		set_process(false)
		return

	var anterior := Vector2.ZERO
	var primer_puente := nivel.get_node_or_null(RUTA_PRIMER_PUENTE) as TileMapLayer
	if primer_puente:
		anterior = TileMapMaskBounds.get_world_bounds(primer_puente).get_center()
	for numero in [1, 2]:
		var puente := nivel.get_node_or_null(RUTA_PUENTE % numero) as TileMapLayer
		if not puente:
			break
		var cruce := _crear_cruce(puente, anterior)
		cruces.append(cruce)
		anterior = cruce.salida
	_dejar_como_estaba.call_deferred()


func _process(delta: float) -> void:
	_ajustar_velocidad_del_vacio()
	# Ya atrapado: que nada más lo capture mientras cae.
	if jugador.get("mode") == Player.Mode.DEFEATED and jugador.collision_layer != 0:
		jugador.set_deferred("collision_layer", 0)
	_soltar_polvo_de_furia(delta)
	_soltar_polvo_si_esta_quieto(delta)
	if ocupada or not is_instance_valid(vacio) or vacio.get("void_layer") == null:
		return
	if jugador.get("mode") != Player.Mode.USER_CONTROLLED:
		return
	var indice := _cruce_recien_pisado()
	if indice >= 0:
		hechas[indice] = true
		_devorar(indice)


func _crear_cruce(puente: TileMapLayer, anterior: Vector2) -> Dictionary:
	var limites := TileMapMaskBounds.get_world_bounds(puente)
	var centro := limites.get_center()
	var extremo_a := Vector2(centro.x, limites.position.y)
	var extremo_b := Vector2(centro.x, limites.end.y)
	if limites.size.x > limites.size.y:
		extremo_a = Vector2(limites.position.x, centro.y)
		extremo_b = Vector2(limites.end.x, centro.y)
	var entrada := (
		extremo_a
		if extremo_a.distance_to(anterior) < extremo_b.distance_to(anterior)
		else extremo_b
	)
	var salida := extremo_b if entrada == extremo_a else extremo_a
	var direccion := (salida - entrada).normalized()
	var medio := ruta.curve.get_closest_offset(ruta.to_local(centro))
	var mitad := entrada.distance_to(salida) / 2.0
	return {
		"puente": puente,
		"entrada": entrada,
		"salida": salida,
		"direccion": direccion,
		"tramo_entrada": medio - mitad,
		"tramo_salida": medio + mitad,
		"llegada": _isla_de_llegada(salida, direccion),
	}


func _cruce_recien_pisado() -> int:
	var reparados: Array = (nivel.get_script() as GDScript).get("puentes_listos")
	var celda := suelo.local_to_map(suelo.to_local(jugador.global_position))
	for indice in cruces.size():
		if hechas[indice] or indice >= reparados.size() or not reparados[indice]:
			continue
		var cruce := cruces[indice]
		var lejos: bool = jugador.global_position.distance_to(cruce.salida) > DISTANCIA_DE_DISPARO
		if lejos and (cruce.llegada as Dictionary).has(celda):
			return indice
	return -1


func _soltar_polvo_si_esta_quieto(delta: float) -> void:
	# El vacío quieto no emite partículas, así que se piden a mano para que se vea
	if not vacio_esperando or not is_instance_valid(vacio):
		return
	proximo_polvo -= delta
	if proximo_polvo <= 0.0:
		proximo_polvo = PAUSA_ENTRE_POLVOS
		vacio.call("_emit_particles")


func _devorar(indice: int) -> void:
	ocupada = true
	var cruce := cruces[indice]

	var sombras := _congelar_todo_para_devorar()
	var celdas := _celdas_de_la_isla_que_se_deja(cruce)
	var centro := _centro_de(celdas)

	var camara := get_viewport().get_camera_2d()
	var posicion_camara := camara.position
	var zoom_camara := camara.zoom
	var suavizado := camara.position_smoothing_enabled
	camara.position_smoothing_enabled = false
	await _alejar_camara(camara, centro, zoom_camara)

	await _devorar_la_isla(cruce, celdas, centro)
	await _cruzar_el_puente(cruce, camara)

	await _volver_camara(camara, posicion_camara, zoom_camara)
	camara.position_smoothing_enabled = suavizado

	await _devolver_el_mundo(indice, sombras)


func _congelar_todo_para_devorar() -> Dictionary:
	jugador.take_control(self)
	jugador.velocity = Vector2.ZERO
	var sombras := _congelar_sombras()
	_permitir_captura(false)
	vacio.path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	return sombras


func _punto_de(celda: Vector2i) -> Vector2:
	return suelo.to_global(suelo.map_to_local(celda))


func _centro_de(celdas: Array[Vector2i]) -> Vector2:
	var centro := Vector2.ZERO
	for celda in celdas:
		centro += _punto_de(celda)
	if not celdas.is_empty():
		centro /= float(celdas.size())
	return centro


func _radio_de(celdas: Array[Vector2i], centro: Vector2) -> float:
	var radio := 0.0
	for celda in celdas:
		radio = maxf(radio, centro.distance_to(_punto_de(celda)))
	return radio


func _alejar_camara(camara: Camera2D, centro: Vector2, zoom_original: Vector2) -> void:
	var alejar := create_tween().set_parallel(true)
	alejar.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	alejar.tween_property(camara, "global_position", centro, TIEMPO_CAMARA)
	alejar.tween_property(camara, "zoom", zoom_original * ZOOM_AL_ALEJAR, TIEMPO_CAMARA)
	await alejar.finished


func _volver_camara(camara: Camera2D, posicion: Vector2, zoom: Vector2) -> void:
	var volver := create_tween().set_parallel(true)
	volver.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	volver.tween_property(camara, "position", posicion, TIEMPO_CAMARA)
	volver.tween_property(camara, "zoom", zoom, TIEMPO_CAMARA)
	await volver.finished
	camara.position = posicion


func _devorar_la_isla(cruce: Dictionary, celdas: Array[Vector2i], centro: Vector2) -> void:
	var pie_del_puente := ruta.to_global(ruta.curve.sample_baked(cruce.tramo_entrada))
	var pendientes: Array[Vector2i] = celdas.duplicate()
	var radio_isla := _radio_de(celdas, centro)
	var radio_vuelta := radio_isla * PARTE_DEL_RADIO_PARA_LA_VUELTA
	var alcance := radio_isla - radio_vuelta + DISTANCIA_PUENTE_A_ISLA
	var angulo := (pie_del_puente - centro).angle()
	var duracion_vuelta := maxf(TAU * radio_vuelta / VELOCIDAD_AL_DEVORAR, TIEMPO_MINIMO)
	_desvanecer_lo_que_hay_en(celdas, duracion_vuelta + TIEMPO_RESTOS)
	var alerta: AnimationPlayer = vacio.get("alert_animation")
	if alerta:
		alerta.play(&"alert")
	await _crecer_la_furia(pendientes, alcance)
	if _tramo_actual() < cruce.tramo_salida:
		await _llevar_al_vacio(
			centro + Vector2.from_angle(angulo) * radio_vuelta, pendientes, alcance
		)
		await _dar_la_vuelta(centro, angulo, radio_vuelta, duracion_vuelta, pendientes, alcance)
	await _ir_por_los_restos(pendientes, pie_del_puente)


func _crecer_la_furia(pendientes: Array[Vector2i], alcance: float) -> void:
	var crecer := create_tween()
	crecer.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	crecer.tween_property(self, "furia", alcance, TIEMPO_CRECER)
	while crecer.is_running():
		_devorar_cerca_del_vacio(pendientes, furia)
		await get_tree().process_frame


func _dar_la_vuelta(
	centro: Vector2,
	angulo: float,
	radio: float,
	duracion: float,
	pendientes: Array[Vector2i],
	alcance: float
) -> void:
	var vuelta := create_tween()
	vuelta.tween_method(
		func(giro: float) -> void:
			vacio.global_position = centro + Vector2.from_angle(angulo + giro) * radio,
		0.0,
		TAU,
		duracion
	)
	while vuelta.is_running():
		_devorar_cerca_del_vacio(pendientes, alcance)
		await get_tree().process_frame


func _cruzar_el_puente(cruce: Dictionary, camara: Camera2D) -> void:
	var puente: TileMapLayer = cruce.puente
	Retejido.sonar_caida(puente)
	Retejido.deshacer_por_franjas(puente, TIEMPO_CRUZAR_PUENTE, cruce.direccion)
	var cruzar := create_tween().set_parallel(true)
	cruzar.tween_method(
		_poner_vacio_en_el_tramo, cruce.tramo_entrada, cruce.tramo_salida, TIEMPO_CRUZAR_PUENTE
	)
	cruzar.tween_property(camara, "global_position", cruce.salida, TIEMPO_CRUZAR_PUENTE)
	var calmar := cruzar.tween_property(
		self, "furia", 0.0, TIEMPO_CRUZAR_PUENTE * PARTE_DEL_PUENTE_PARA_CALMARSE
	)
	calmar.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await cruzar.finished
	await get_tree().create_timer(PAUSA_FINAL).timeout


func _devolver_el_mundo(indice: int, sombras: Dictionary) -> void:
	vacio.state = ESTADO_RONDA
	var ventaja := VENTAJA_POR_ISLA[mini(indice + 1, VENTAJA_POR_ISLA.size() - 1)]
	if ventaja > 0.0:
		vacio.path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
		vacio_esperando = true
	_descongelar_sombras(sombras)
	_devolver_el_control()
	ocupada = false
	await get_tree().create_timer(maxf(TIEMPO_SIN_CAPTURA, ventaja), false).timeout
	vacio_esperando = false
	if is_instance_valid(vacio) and vacio.state == ESTADO_RONDA:
		vacio.path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
	_permitir_captura(true)


func _dejar_como_estaba() -> void:
	var ultima := -1
	for indice in cruces.size():
		if not hechas[indice]:
			continue
		ultima = indice
		var cruce := cruces[indice]
		var celdas := _celdas_de_la_isla_que_se_deja(cruce)
		_desvanecer_lo_que_hay_en(celdas, 0.0)
		_consumir(celdas, true)
		var puente: TileMapLayer = cruce.puente
		puente.enabled = false
		puente.hide()
	if ultima >= 0:
		_poner_vacio_en_el_tramo(cruces[ultima].tramo_salida)


func _soltar_polvo_de_furia(delta: float) -> void:
	if furia <= 0.0 or not is_instance_valid(vacio):
		return
	proxima_nube_de_furia -= delta
	if proxima_nube_de_furia > 0.0:
		return
	proxima_nube_de_furia = PAUSA_ENTRE_NUBES_DE_FURIA
	var nubes: PackedScene = vacio.get("void_particles")
	var grupo: Node = vacio.get("particles_canvas_group")
	if not nubes or not grupo or grupo.get_child_count() >= MAXIMO_DE_NUBES_VIVAS:
		return
	var alcance_del_polvo := maxf(furia - RADIO_DE_UNA_NUBE, 0.0)
	for i in int(ceil(furia / FURIA_POR_NUBE)):
		var nube: GPUParticles2D = nubes.instantiate()
		nube.position = Vector2.from_angle(randf() * TAU) * alcance_del_polvo * sqrt(randf())
		nube.emitting = true
		nube.finished.connect(nube.queue_free)
		grupo.add_child(nube)


func _ajustar_velocidad_del_vacio() -> void:
	if not is_instance_valid(vacio) or not ruta:
		return
	var tramo := _tramo_actual()
	var isla := 0
	for cruce in cruces:
		if tramo >= cruce.tramo_salida - MARGEN_DE_SALIDA_DEL_PUENTE:
			isla += 1
	var velocidad := VELOCIDAD_POR_ISLA[mini(isla, VELOCIDAD_POR_ISLA.size() - 1)]
	velocidad *= ElHiloQueNoTejiState.alivio_por_muertes(
		"sequence_puzzle", FRENO_POR_MUERTE, VELOCIDAD_MINIMA
	)
	var paso: Node = vacio.path_walk_behavior
	if not velocidades_del_vacio:
		# Copia propia: la original es un recurso compartido de Threadbare.
		velocidades_del_vacio = paso.speeds.duplicate()
		paso.speeds = velocidades_del_vacio
	velocidades_del_vacio.walk_speed = velocidad


func _tramo_actual() -> float:
	return ruta.curve.get_closest_offset(ruta.to_local(vacio.global_position))


func _poner_vacio_en_el_tramo(tramo: float) -> void:
	vacio.global_position = ruta.to_global(ruta.curve.sample_baked(tramo))


func _consumir(celdas: Array[Vector2i], al_instante: bool = false) -> void:
	var capa_vacio: TileMapLayer = vacio.get("void_layer")
	if not capa_vacio or celdas.is_empty():
		return
	var lote: Array[Vector2i] = []
	for celda in celdas:
		lote.append(capa_vacio.local_to_map(capa_vacio.to_local(_punto_de(celda))))
	capa_vacio.call("consume_cells", lote, al_instante)


func _devorar_cerca_del_vacio(pendientes: Array[Vector2i], radio: float) -> void:
	var cerca: Array[Vector2i] = []
	for i in range(pendientes.size() - 1, -1, -1):
		if _punto_de(pendientes[i]).distance_to(vacio.global_position) <= radio:
			cerca.append(pendientes[i])
			pendientes.remove_at(i)
	_consumir(cerca)


func _ir_por_los_restos(pendientes: Array[Vector2i], regreso: Vector2) -> void:
	var viajes := 0
	while not pendientes.is_empty() and viajes < VIAJES_MAXIMOS:
		viajes += 1
		await _llevar_al_vacio(_resto_mas_cercano(pendientes), pendientes, RADIO_AL_DEVORAR)
	_devorar_cerca_del_vacio(pendientes, INF)
	await _llevar_al_vacio(regreso, pendientes, RADIO_AL_DEVORAR)


func _resto_mas_cercano(pendientes: Array[Vector2i]) -> Vector2:
	var destino := vacio.global_position
	var mas_cerca := INF
	for celda in pendientes:
		var punto := _punto_de(celda)
		var distancia := punto.distance_to(vacio.global_position)
		if distancia < mas_cerca:
			mas_cerca = distancia
			destino = punto
	return destino


func _llevar_al_vacio(destino: Vector2, pendientes: Array[Vector2i], alcance: float) -> void:
	while vacio.global_position.distance_to(destino) > DISTANCIA_DE_LLEGADA:
		vacio.global_position = vacio.global_position.move_toward(
			destino, VELOCIDAD_AL_DEVORAR * get_process_delta_time()
		)
		_devorar_cerca_del_vacio(pendientes, alcance)
		await get_tree().process_frame


func _isla_de_llegada(salida: Vector2, direccion: Vector2) -> Dictionary:
	var llegada: Dictionary = {}
	for celda in _celdas_de_la_isla(
		salida + direccion * DISTANCIA_PUENTE_A_ISLA, CELDAS_MAXIMAS_DE_LLEGADA
	):
		llegada[celda] = true
	return llegada


func _celdas_de_la_isla_que_se_deja(cruce: Dictionary) -> Array[Vector2i]:
	return _celdas_de_la_isla(cruce.entrada - cruce.direccion * DISTANCIA_PUENTE_A_ISLA)


func _celdas_de_la_isla(punto: Vector2, maximo: int = CELDAS_MAXIMAS) -> Array[Vector2i]:
	var inicio := suelo.local_to_map(suelo.to_local(punto))
	var isla: Array[Vector2i] = []
	if suelo.get_cell_source_id(inicio) == -1:
		var mejor := INF
		for celda in suelo.get_used_cells():
			var distancia := Vector2(celda - inicio).length()
			if distancia < mejor:
				mejor = distancia
				inicio = celda
		if mejor > MAXIMA_DISTANCIA_A_UNA_CELDA:
			return isla
	var vistas: Dictionary = {inicio: true}
	var pendientes: Array[Vector2i] = [inicio]
	while not pendientes.is_empty() and isla.size() < maximo:
		var celda: Vector2i = pendientes.pop_back()
		isla.append(celda)
		for vecina in VECINAS:
			var otra: Vector2i = celda + vecina
			if not vistas.has(otra) and suelo.get_cell_source_id(otra) != -1:
				vistas[otra] = true
				pendientes.append(otra)
	return isla


func _desvanecer_lo_que_hay_en(celdas: Array[Vector2i], duracion: float) -> void:
	var cosas := _cosas_en(celdas)
	if cosas.is_empty():
		return
	var ocultar := func() -> void:
		for cosa in cosas:
			if is_instance_valid(cosa):
				cosa.hide()
				cosa.process_mode = Node.PROCESS_MODE_DISABLED
	if duracion <= 0.0:
		ocultar.call()
		return
	var desvanecer := create_tween().set_parallel(true)
	for cosa in cosas:
		desvanecer.tween_property(cosa, "modulate:a", 0.0, duracion)
	desvanecer.chain().tween_callback(ocultar)


func _cosas_en(celdas: Array[Vector2i]) -> Array[Node2D]:
	var de_la_isla: Dictionary = {}
	for celda in celdas:
		de_la_isla[celda] = true
	var cosas: Array[Node2D] = []
	for hijo in nivel.get_node(RUTA_EN_EL_SUELO).get_children():
		if not _se_puede_desvanecer(hijo):
			continue
		for pieza in _piezas_de(hijo):
			var celda := suelo.local_to_map(suelo.to_local((pieza as Node2D).global_position))
			if de_la_isla.has(celda):
				cosas.append(hijo as Node2D)
				break
	return cosas


func _se_puede_desvanecer(hijo: Node) -> bool:
	if hijo == jugador or hijo == vacio or hijo.name == NOMBRE_DE_LUTO:
		return false
	return hijo is Node2D and not hijo is Path2D


func _piezas_de(hijo: Node) -> Array[Node]:
	if String(hijo.name).begins_with(PREFIJO_DE_PUZZLE):
		return hijo.find_children("*", "Node2D", true, false)
	return [hijo]


func _devolver_el_control() -> void:
	# atrapado: return_control lo dejaría vivo otra vez y moriría dos veces
	if jugador.get("mode") == Player.Mode.DEFEATED:
		jugador.get("_system_controllers").erase(self)
		return
	jugador.return_control(self)


func _permitir_captura(permitir: bool) -> void:
	if not is_instance_valid(vacio):
		return
	var captura := vacio.get_node_or_null("PlayerCaptureArea") as Area2D
	if captura:
		captura.set_deferred("monitoring", permitir)


func _congelar_sombras() -> Dictionary:
	var congeladas: Dictionary = {}
	for sombra in get_tree().get_nodes_in_group("guard_enemy"):
		congeladas[sombra] = sombra.process_mode
		sombra.process_mode = Node.PROCESS_MODE_DISABLED
	return congeladas


func _descongelar_sombras(congeladas: Dictionary) -> void:
	for sombra in congeladas:
		if is_instance_valid(sombra) and sombra.is_visible_in_tree():
			sombra.process_mode = congeladas[sombra]
