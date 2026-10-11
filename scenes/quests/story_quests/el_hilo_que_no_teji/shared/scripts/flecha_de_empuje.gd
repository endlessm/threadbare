# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Flecha que muestra hacia dónde saldría un proyectil si Lino lo repele ahora.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const DISTANCIA_VISIBLE: float = 170.0
const DISTANCIA_PLENA: float = 80.0
const SEPARACION: float = 26.0
const LARGO: float = 45.0
const GROSOR: float = 5.0
const PUNTA: float = 12.0
const COLOR_FLECHA := Color(1.0, 1.0, 1.0, 0.85)
const COLOR_BORDE := Color(0.0, 0.0, 0.0, 0.5)
const CENTRO_JARRON := Vector2(0, -24)
const COLOR_BRILLO_JARRON := Color(1.0, 0.85, 0.4, 0.9)
const NODO_REPELER: NodePath = ^"PlayerRepel"
const GRUPO_PROYECTILES: StringName = &"projectiles"
const META_CON_FLECHA: StringName = &"con_flecha"
const OPACIDAD_MINIMA_VISIBLE: float = 0.01
const MAXIMO_DE_REBOTES: int = 2
const ALCANCE_RAYO: float = 1600.0
const MEDIO_ANCHO_PROYECTIL: float = 20.0
const CAPA_PROYECTIL: int = 256
const MASCARA_PROYECTIL: int = 80
const TODAS_LAS_CAPAS: int = 0xFFFFFFFF
const INTENTOS_DEL_RAYO: int = 12
const Z_INDEX_DE_LA_FLECHA: int = 30
const VELOCIDAD_DE_APARICION_FLECHA: float = 6.0
const VELOCIDAD_DE_APARICION_BRILLO: float = 5.0
const TAMANO_TEXTURA_BRILLO: int = 128
const ESCALA_BRILLO := Vector2(1.5, 1.5)
const ANCHO_PUNTA: float = 0.7
const AVANCE_PUNTA: float = 0.4
const ENGROSE_DEL_BORDE: float = 4.0
const ENSANCHE_BORDE_PUNTA: float = 1.35
const RETROCESO_BORDE_PUNTA: float = 3.0

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
	queue_redraw()


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
	_apuntado = null
	if not is_instance_valid(_proyectil) or _direccion == Vector2.ZERO:
		return
	var espacio := get_world_2d().direct_space_state
	var cuerpo := _proyectil as CollisionObject2D
	var capa: int = cuerpo.collision_layer if cuerpo else CAPA_PROYECTIL
	var mascara: int = cuerpo.collision_mask if cuerpo else MASCARA_PROYECTIL
	var propio: Array[RID] = []
	if cuerpo:
		propio.append(cuerpo.get_rid())

	var inicio: Vector2 = _desde
	var direccion: Vector2 = _direccion
	for _rebote in MAXIMO_DE_REBOTES + 1:
		var choque := _primer_choque(espacio, inicio, direccion, propio, capa, mascara)
		if choque.is_empty():
			return
		var jarron := _jarron_de(choque)
		if jarron:
			_apuntado = jarron
			return
		inicio += direccion * maxf(float(choque.avance) - MEDIO_ANCHO_PROYECTIL, 0.0)
		direccion = direccion.bounce(choque.normal)


func _primer_choque(
	espacio: PhysicsDirectSpaceState2D,
	inicio: Vector2,
	direccion: Vector2,
	propio: Array[RID],
	capa: int,
	mascara: int
) -> Dictionary:
	var mejor: Dictionary = {}
	var lado: Vector2 = direccion.orthogonal() * MEDIO_ANCHO_PROYECTIL
	for origen: Vector2 in [inicio, inicio + lado, inicio - lado]:
		var choque := _lanzar_rayo(espacio, origen, direccion, propio, capa, mascara)
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
	mascara: int
) -> Dictionary:
	# se pide todas las capas y se filtra a mano: un cuerpo puede detectar al proyectil
	# por su máscara aunque el proyectil no lo golpee
	var excluidos: Array[RID] = []
	excluidos.assign(propio)
	for _intento in INTENTOS_DEL_RAYO:
		var consulta := PhysicsRayQueryParameters2D.create(
			origen, origen + direccion * ALCANCE_RAYO, TODAS_LAS_CAPAS, excluidos
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


func _draw() -> void:
	if _opacidad <= OPACIDAD_MINIMA_VISIBLE or _direccion == Vector2.ZERO:
		return
	var inicio: Vector2 = _desde + _direccion * SEPARACION
	var fin: Vector2 = inicio + _direccion * LARGO
	var lado: Vector2 = _direccion.orthogonal() * PUNTA * ANCHO_PUNTA
	var base: Vector2 = fin - _direccion * PUNTA
	var punta := PackedVector2Array(
		[fin + _direccion * PUNTA * AVANCE_PUNTA, base + lado, base - lado]
	)

	var borde := COLOR_BORDE
	borde.a *= _opacidad
	var color := COLOR_FLECHA
	color.a *= _opacidad
	draw_line(inicio, base, borde, GROSOR + ENGROSE_DEL_BORDE)
	draw_colored_polygon(
		PackedVector2Array(
			[
				fin + _direccion * (PUNTA * AVANCE_PUNTA + ENGROSE_DEL_BORDE),
				base + lado * ENSANCHE_BORDE_PUNTA - _direccion * RETROCESO_BORDE_PUNTA,
				base - lado * ENSANCHE_BORDE_PUNTA - _direccion * RETROCESO_BORDE_PUNTA,
			]
		),
		borde
	)
	draw_line(inicio, base, color, GROSOR)
	draw_colored_polygon(punta, color)
