# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## El vacío baja desde el norte y deshace los puentes de la primera isla.

# 0 es State.IDLE del enum de VoidSpreadingEnemy: el vacío quieto, esperando.
# Se usa al despertarlo, para que retome su ronda
const ESTADO_RONDA: int = 0

const ESPERA_DEL_VACIO: Vector2 = Vector2(0, -600)
# Segundos extra que dura el deshacerse de cada puente, además de lo que tarda el vacío
# en cruzarlo
const HOLGURA_AL_DESHACER_PUENTE: float = 0.3
# La pausa final dura al menos esto en segundos, aunque pausa_final sea menor
const PAUSA_MINIMA_FINAL: float = 1.0
# Si el vacío ya está a menos de esto (en px) del destino, no se mueve
const DISTANCIA_DE_LLEGADA: float = 1.0

# Es static para que se conserve cuando Lino muere y el nivel se recarga: así la
# cinemática solo se ve una vez (true = ya se vio)
static var vista: bool = false

@export var enemigo_vacio: Node2D
@export var puentes: Array[TileMapLayer]
@export var puentes_rotos: Array[TileMapLayer]
# punto_de_inicio_de_ronda es el número del punto de la ruta de patrulla del vacío
# (empieza en 0) donde termina la cinemática y empieza a patrullar
@export var punto_de_inicio_de_ronda: int = 2

@export_group("Tiempos")
# Los tiempos son segundos y las velocidades son px/s
@export var tiempo_camara_ida: float = 1.2
@export var velocidad_sobre_puente: float = 800.0
@export var velocidad_entre_puentes: float = 1300.0
@export var pausa_final: float = 0.6
@export var tiempo_camara_vuelta: float = 1.0

var capa_del_vacio: TileMapLayer
var camara: Camera2D
var camara_sigue_al_vacio: bool = false


func _ready() -> void:
	body_entered.connect(_al_entrar)
	if vista or not is_instance_valid(enemigo_vacio):
		return
	if not enemigo_vacio.is_node_ready():
		await enemigo_vacio.ready
	_dormir_al_vacio()


func _process(_delta: float) -> void:
	if camara_sigue_al_vacio and is_instance_valid(camara):
		camara.global_position = enemigo_vacio.global_position


func _dormir_al_vacio() -> void:
	capa_del_vacio = enemigo_vacio.void_layer
	# Mientras el vacío está dormido se le quita su capa de tiles (void_layer) para que no
	# borre nada; _despertar_al_vacio se la devuelve
	enemigo_vacio.void_layer = null
	enemigo_vacio.path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	enemigo_vacio.idle_sfx.stop()
	_permitir_captura(false)
	if not puentes.is_empty():
		enemigo_vacio.global_position = _extremos(puentes[0])[0] + ESPERA_DEL_VACIO


func _al_entrar(cuerpo: Node2D) -> void:
	if vista or not cuerpo.is_in_group("player") or not is_instance_valid(enemigo_vacio):
		return
	vista = true

	cuerpo.take_control(self)
	cuerpo.velocity = Vector2.ZERO
	var sombras := _congelar_sombras()

	camara = get_viewport().get_camera_2d()
	var posicion_camara := camara.position
	var suavizado := camara.position_smoothing_enabled
	camara.position_smoothing_enabled = false

	var posicion := _extremo_mas_lejano(puentes[0], cuerpo.global_position)
	enemigo_vacio.global_position = posicion

	var ida := create_tween()
	ida.tween_property(camara, "global_position", posicion, tiempo_camara_ida).set_trans(
		Tween.TRANS_SINE
	)
	await ida.finished
	camara_sigue_al_vacio = true

	await _deshacer_los_puentes(posicion)

	await _mover_vacio(_inicio_de_ronda(), velocidad_sobre_puente)
	await get_tree().create_timer(maxf(pausa_final, PAUSA_MINIMA_FINAL)).timeout

	camara_sigue_al_vacio = false
	var vuelta := create_tween()
	vuelta.tween_property(camara, "position", posicion_camara, tiempo_camara_vuelta).set_trans(
		Tween.TRANS_QUAD
	)
	await vuelta.finished
	camara.position = posicion_camara
	camara.position_smoothing_enabled = suavizado

	_despertar_al_vacio()
	_descongelar_sombras(sombras)
	# Si a Lino ya lo atraparon, devolverle el control lo haría morir dos veces.
	if cuerpo.get("mode") != Player.Mode.DEFEATED:
		cuerpo.return_control(self)


func _deshacer_los_puentes(posicion_inicial: Vector2) -> void:
	var posicion := posicion_inicial
	for i in puentes.size():
		var extremos := _extremos(puentes[i])
		var entrada := extremos[0]
		var salida := extremos[1]
		if salida.distance_to(posicion) < entrada.distance_to(posicion):
			entrada = extremos[1]
			salida = extremos[0]

		await _mover_vacio(entrada, velocidad_entre_puentes)

		var duracion := entrada.distance_to(salida) / velocidad_sobre_puente
		_deshacer_puente(puentes[i], duracion + HOLGURA_AL_DESHACER_PUENTE, salida - entrada, i)
		await _mover_vacio(salida, velocidad_sobre_puente)
		posicion = salida


func _deshacer_puente(puente: TileMapLayer, duracion: float, avance: Vector2, indice: int) -> void:
	Retejido.sonar_caida(puente)
	await Retejido.deshacer_por_franjas(puente, duracion, avance)
	if indice < puentes_rotos.size() and is_instance_valid(puentes_rotos[indice]):
		Retejido.aparecer(puentes_rotos[indice], Retejido.DURACION_BREVE)


func _mover_vacio(destino: Vector2, velocidad: float) -> void:
	var distancia := enemigo_vacio.global_position.distance_to(destino)
	if distancia < DISTANCIA_DE_LLEGADA:
		return
	var viaje := create_tween()
	viaje.tween_property(enemigo_vacio, "global_position", destino, distancia / velocidad)
	await viaje.finished


func _despertar_al_vacio() -> void:
	enemigo_vacio.void_layer = capa_del_vacio
	enemigo_vacio.state = ESTADO_RONDA
	_permitir_captura(true)


func _inicio_de_ronda() -> Vector2:
	var ruta: Path2D = enemigo_vacio.idle_patrol_path
	if not ruta or ruta.curve.point_count == 0:
		return enemigo_vacio.global_position
	var punto := clampi(punto_de_inicio_de_ronda, 0, ruta.curve.point_count - 1)
	return ruta.to_global(ruta.curve.get_point_position(punto))


func _permitir_captura(permitir: bool) -> void:
	var captura := enemigo_vacio.get_node_or_null("PlayerCaptureArea") as Area2D
	if captura:
		captura.set_deferred("monitoring", permitir)


# Los dos extremos del puente por su lado largo: arriba y abajo si es vertical,
# izquierda y derecha si es horizontal
func _extremos(puente: TileMapLayer) -> Array[Vector2]:
	var limites := TileMapMaskBounds.get_world_bounds(puente)
	var centro := limites.get_center()
	if limites.size.y >= limites.size.x:
		return [Vector2(centro.x, limites.position.y), Vector2(centro.x, limites.end.y)]
	return [Vector2(limites.position.x, centro.y), Vector2(limites.end.x, centro.y)]


func _extremo_mas_lejano(puente: TileMapLayer, desde: Vector2) -> Vector2:
	var extremos := _extremos(puente)
	if extremos[1].distance_to(desde) > extremos[0].distance_to(desde):
		return extremos[1]
	return extremos[0]


func _congelar_sombras() -> Dictionary:
	var congeladas: Dictionary = {}
	for sombra in get_tree().get_nodes_in_group("guard_enemy"):
		congeladas[sombra] = sombra.process_mode
		sombra.process_mode = Node.PROCESS_MODE_DISABLED
	return congeladas


func _descongelar_sombras(congeladas: Dictionary) -> void:
	for sombra in congeladas:
		if is_instance_valid(sombra):
			sombra.process_mode = congeladas[sombra]
