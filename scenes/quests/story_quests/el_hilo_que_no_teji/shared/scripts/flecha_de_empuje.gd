# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Hilo de puntadas que muestra hacia dónde saldría un proyectil si Lino lo repele ahora.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const DISTANCIA_VISIBLE: float = 170.0
const DISTANCIA_PLENA: float = 80.0
const SEPARACION_DEL_HILO: float = 26.0
const LARGO_DEL_HILO: float = 150.0
const LARGO_DEL_HILO_APUNTANDO: float = 230.0
const LARGO_DE_LA_PUNTADA: float = 14.0
const HUECO_ENTRE_PUNTADAS: float = 9.0
const GROSOR_DEL_HILO: float = 4.0
const GROSOR_EXTRA_DE_LA_SOMBRA: float = 3.0
const VELOCIDAD_DE_LAS_PUNTADAS: float = 38.0
const COLOR_HILO := Color(1.0, 0.95, 0.82, 0.95)
const COLOR_HILO_APUNTANDO := Color(1.0, 0.85, 0.4, 1.0)
const COLOR_SOMBRA_DEL_HILO := Color(0.0, 0.0, 0.0, 0.35)
const CENTRO_JARRON := Vector2(0, -24)
const COLOR_BRILLO_JARRON := Color(1.0, 0.85, 0.4, 0.9)
const NODO_REPELER: NodePath = ^"PlayerRepel"
const GRUPO_PROYECTILES: StringName = &"projectiles"
const META_CON_FLECHA: StringName = &"con_flecha"
const OPACIDAD_MINIMA_VISIBLE: float = 0.01
## Tope de seguridad: lo que de verdad limita el trayecto es la distancia que el proyectil puede
## recorrer (ver _fisica_del_proyectil), no cuántas veces rebota.
const MAXIMO_DE_REBOTES: int = 8
## Roce que el motor aplica por defecto a los cuerpos si el proyecto no dice otra cosa.
const ROCE_POR_DEFECTO: float = 0.1
const ALCANCE_RAYO: float = 1600.0
const MEDIO_ANCHO_PROYECTIL: float = 20.0
const CAPA_PROYECTIL: int = 256
const MASCARA_PROYECTIL: int = 80
const TODAS_LAS_CAPAS: int = 0xFFFFFFFF
const INTENTOS_DEL_RAYO: int = 6
## Los rayos se lanzan cada tantos cuadros de física: la dirección del hilo no cambia tan rápido.
const CUADROS_ENTRE_RAYOS: int = 3
const Z_INDEX_DE_LA_FLECHA: int = 30
const VELOCIDAD_DE_APARICION_FLECHA: float = 6.0
const VELOCIDAD_DE_APARICION_BRILLO: float = 5.0
const TAMANO_TEXTURA_BRILLO: int = 128
const ESCALA_BRILLO := Vector2(1.5, 1.5)

var jugador: Node2D
var jarrones: Array = []
var activa: bool = false

var _origen: Node2D
var _desde := Vector2.ZERO
var _direccion := Vector2.ZERO
var _opacidad: float = 0.0
var _brillos: Dictionary = {}
var _apuntado: Node2D
var _proyectil: Node2D
var _cuadros_de_fisica: int = 0
var _dibujado: bool = false


func _ready() -> void:
	top_level = true
	z_index = Z_INDEX_DE_LA_FLECHA
	if is_instance_valid(jugador):
		_origen = jugador.get_node_or_null(NODO_REPELER)
		if not _origen:
			_origen = jugador


func _process(delta: float) -> void:
	var objetivo: float = 0.0
	var proyectil := _proyectil_mas_cercano() if activa else null
	if proyectil:
		var centro: Vector2 = _origen.global_position
		var distancia: float = centro.distance_to(proyectil.global_position)
		_direccion = centro.direction_to(proyectil.global_position)
		_desde = proyectil.global_position
		objetivo = clampf(inverse_lerp(DISTANCIA_VISIBLE, DISTANCIA_PLENA, distancia), 0.0, 1.0)
	_proyectil = proyectil

	_opacidad = move_toward(_opacidad, objetivo, delta * VELOCIDAD_DE_APARICION_FLECHA)
	_actualizar_brillos(_apuntado if proyectil else null, delta)
	# no se redibuja mientras no se ve: en la web cada redibujado cuesta
	var se_ve: bool = _opacidad > OPACIDAD_MINIMA_VISIBLE
	if se_ve or _dibujado:
		queue_redraw()
	_dibujado = se_ve


func _proyectil_mas_cercano() -> Node2D:
	if not is_instance_valid(_origen):
		return null
	var mejor: Node2D = null
	var menor: float = DISTANCIA_VISIBLE
	for nodo in get_tree().get_nodes_in_group(GRUPO_PROYECTILES):
		var proyectil := nodo as Node2D
		if not proyectil or proyectil.is_queued_for_deletion():
			continue
		if not proyectil.has_meta(META_CON_FLECHA):
			continue
		var distancia: float = _origen.global_position.distance_to(proyectil.global_position)
		if distancia < menor:
			menor = distancia
			mejor = proyectil
	return mejor


# los rayos solo se pueden lanzar en _physics_process
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_proyectil) or _direccion == Vector2.ZERO:
		_apuntado = null
		return
	_cuadros_de_fisica += 1
	if _cuadros_de_fisica % CUADROS_ENTRE_RAYOS != 0:
		return
	_apuntado = null
	var espacio := get_world_2d().direct_space_state
	var cuerpo := _proyectil as CollisionObject2D
	var capa: int = cuerpo.collision_layer if cuerpo else CAPA_PROYECTIL
	var mascara: int = cuerpo.collision_mask if cuerpo else MASCARA_PROYECTIL
	var propio: Array[RID] = []
	if cuerpo:
		propio.append(cuerpo.get_rid())

	# Al repelerlo el proyectil sale con una rapidez y la va perdiendo por el roce. Cada choque
	# le reinicia la vida, pero no la rapidez: por eso se mide el trayecto en distancia total.
	var fisica := _fisica_del_proyectil(_proyectil)
	var inicio: Vector2 = _desde
	var direccion: Vector2 = _direccion
	var recorrido: float = 0.0
	for _rebote in MAXIMO_DE_REBOTES + 1:
		var alcance: float = ALCANCE_RAYO
		if not fisica.is_empty():
			alcance = minf(alcance, _alcance_del_tramo(recorrido, fisica))
		if alcance <= MEDIO_ANCHO_PROYECTIL:
			return
		var choque := _primer_choque(espacio, inicio, direccion, propio, capa, mascara, alcance)
		if choque.is_empty():
			return
		var jarron := _jarron_de(choque)
		if jarron:
			_apuntado = jarron
			return
		var avance: float = maxf(float(choque.avance) - MEDIO_ANCHO_PROYECTIL, 0.0)
		inicio += direccion * avance
		recorrido += avance
		direccion = direccion.bounce(choque.normal)


## Con qué rapidez sale el proyectil al ser repelido, cuánta pierde por el roce y cuánto vive
## sin chocar. Vacío si no se pueden leer (entonces el rayo usa su alcance máximo).
func _fisica_del_proyectil(proyectil: Node) -> Dictionary:
	var golpe: Variant = proyectil.get("hit_speed")
	var masa: Variant = proyectil.get("mass")
	var vida: Variant = proyectil.get("duration")
	if not (golpe is float and masa is float and vida is float):
		return {}
	if (masa as float) <= 0.0 or (vida as float) <= 0.0:
		return {}
	var roce: float = float(
		ProjectSettings.get_setting("physics/2d/default_linear_damp", ROCE_POR_DEFECTO)
	)
	var cuerpo := proyectil as RigidBody2D
	if cuerpo:
		if cuerpo.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE:
			roce = cuerpo.linear_damp
		else:
			roce += cuerpo.linear_damp
	# el impulso del golpe se reparte entre la masa: rapidez = impulso / masa
	return {"rapidez": (golpe as float) / (masa as float), "roce": roce, "vida": vida as float}


## Hasta dónde puede llegar el proyectil en este tramo: lo que recorre en su vida desde el último
## choque. Si ya agotó lo que el roce le deja recorrer, devuelve 0.
func _alcance_del_tramo(recorrido: float, fisica: Dictionary) -> float:
	var t_choque: float = _tiempo_para(recorrido, fisica)
	if is_inf(t_choque):
		return 0.0
	return _distancia_en(t_choque + float(fisica.vida), fisica) - recorrido


## Distancia recorrida tras t segundos: v0 * (1 - e^(-roce*t)) / roce.
func _distancia_en(t: float, fisica: Dictionary) -> float:
	var v0: float = fisica.rapidez
	var roce: float = fisica.roce
	if roce < 0.0001:
		return v0 * t
	return v0 * (1.0 - exp(-roce * t)) / roce


## Segundos que tarda en recorrer una distancia; INF si el roce lo detiene antes.
func _tiempo_para(distancia: float, fisica: Dictionary) -> float:
	var v0: float = fisica.rapidez
	var roce: float = fisica.roce
	if roce < 0.0001:
		return distancia / v0
	var resto: float = 1.0 - roce * distancia / v0
	if resto <= 0.0:
		return INF
	return -log(resto) / roce


func _primer_choque(
	espacio: PhysicsDirectSpaceState2D,
	inicio: Vector2,
	direccion: Vector2,
	propio: Array[RID],
	capa: int,
	mascara: int,
	alcance: float
) -> Dictionary:
	var mejor: Dictionary = {}
	var lado: Vector2 = direccion.orthogonal() * MEDIO_ANCHO_PROYECTIL
	for origen: Vector2 in [inicio, inicio + lado, inicio - lado]:
		var choque := _lanzar_rayo(espacio, origen, direccion, propio, capa, mascara, alcance)
		if choque.is_empty():
			continue
		choque.avance = origen.distance_to(choque.position)
		if mejor.is_empty() or choque.avance < mejor.avance:
			mejor = choque
	return mejor


func _lanzar_rayo(
	espacio: PhysicsDirectSpaceState2D,
	origen: Vector2,
	direccion: Vector2,
	propio: Array[RID],
	capa: int,
	mascara: int,
	alcance: float
) -> Dictionary:
	# se pide todas las capas y se filtra a mano: un cuerpo puede detectar al proyectil
	# por su máscara aunque el proyectil no lo golpee
	var excluidos: Array[RID] = []
	excluidos.assign(propio)
	for _intento in INTENTOS_DEL_RAYO:
		var consulta := PhysicsRayQueryParameters2D.create(
			origen, origen + direccion * alcance, TODAS_LAS_CAPAS, excluidos
		)
		var choque: Dictionary = espacio.intersect_ray(consulta)
		if choque.is_empty():
			return {}
		var rid: RID = choque.rid
		var capa_cuerpo: int = PhysicsServer2D.body_get_collision_layer(rid)
		var mascara_cuerpo: int = PhysicsServer2D.body_get_collision_mask(rid)
		if (capa_cuerpo & mascara) != 0 or (mascara_cuerpo & capa) != 0:
			return choque
		excluidos.append(rid)
	return {}


func _jarron_de(choque: Dictionary) -> Node2D:
	if choque.is_empty():
		return null
	var cuerpo := choque.collider as Node
	for jarron in jarrones:
		if not is_instance_valid(jarron) or jarron.is_queued_for_deletion():
			continue
		if cuerpo == jarron or jarron.is_ancestor_of(cuerpo):
			return jarron
	return null


func _actualizar_brillos(apuntado: Node2D, delta: float) -> void:
	if apuntado and not _brillos.has(apuntado):
		_brillos[apuntado] = _crear_brillo(apuntado)
	for jarron in _brillos.keys():
		var brillo: Sprite2D = _brillos[jarron]
		if not is_instance_valid(jarron) or jarron.is_queued_for_deletion():
			brillo.queue_free()
			_brillos.erase(jarron)
			continue
		var meta: float = _opacidad if jarron == apuntado else 0.0
		brillo.modulate.a = move_toward(
			brillo.modulate.a, meta, delta * VELOCIDAD_DE_APARICION_BRILLO
		)


func _crear_brillo(jarron: Node2D) -> Sprite2D:
	var textura := AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_BRILLO)
	var suma := AyudasDeEscena.material_de_suma()

	var brillo := Sprite2D.new()
	brillo.texture = textura
	brillo.material = suma
	brillo.self_modulate = COLOR_BRILLO_JARRON
	brillo.modulate.a = 0.0
	brillo.scale = ESCALA_BRILLO
	add_child(brillo)
	brillo.global_position = jarron.global_position + CENTRO_JARRON
	return brillo


## Puntadas que salen del proyectil hacia donde lo empujaría Lino. Avanzan hacia afuera y se
## apagan con la distancia: el movimiento marca el sentido. Se vuelven doradas cuando la
## dirección actual llega a un jarrón. Todas las puntadas se dibujan en dos llamadas.
func _draw() -> void:
	if _opacidad <= OPACIDAD_MINIMA_VISIBLE or _direccion == Vector2.ZERO:
		return
	var apuntando: bool = _apuntado != null
	var largo: float = LARGO_DEL_HILO_APUNTANDO if apuntando else LARGO_DEL_HILO
	var color_base: Color = COLOR_HILO_APUNTANDO if apuntando else COLOR_HILO
	var inicio: Vector2 = _desde + _direccion * SEPARACION_DEL_HILO
	var paso: float = LARGO_DE_LA_PUNTADA + HUECO_ENTRE_PUNTADAS
	var corrimiento: float = fposmod(
		Time.get_ticks_msec() / 1000.0 * VELOCIDAD_DE_LAS_PUNTADAS, paso
	)

	var puntos := PackedVector2Array()
	var colores := PackedColorArray()
	var sombras := PackedColorArray()
	var distancia: float = corrimiento - paso
	while distancia < largo:
		var desde: float = maxf(distancia, 0.0)
		var hasta: float = minf(distancia + LARGO_DE_LA_PUNTADA, largo)
		distancia += paso
		if hasta <= desde:
			continue
		var recorrido: float = (desde + hasta) * 0.5 / largo
		var color: Color = color_base
		color.a *= _opacidad * (1.0 - recorrido * recorrido)
		var sombra: Color = COLOR_SOMBRA_DEL_HILO
		sombra.a *= color.a
		puntos.append(inicio + _direccion * desde)
		puntos.append(inicio + _direccion * hasta)
		colores.append(color)
		sombras.append(sombra)
	if puntos.is_empty():
		return
	draw_multiline_colors(puntos, sombras, GROSOR_DEL_HILO + GROSOR_EXTRA_DE_LA_SOMBRA)
	draw_multiline_colors(puntos, colores, GROSOR_DEL_HILO)
