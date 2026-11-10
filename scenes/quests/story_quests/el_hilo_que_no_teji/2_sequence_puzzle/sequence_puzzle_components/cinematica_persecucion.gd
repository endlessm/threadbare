# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## La cámara mira al vacío y luego este empieza a perseguir a Lino.

const PAUSA_ENTRE_POLVOS: float = 0.12
const FRENO_POR_MUERTE: float = 0.06
const VELOCIDAD_MINIMA: float = 0.6

@export var enemigo_vacio: Node2D

@export_group("Tiempos de la Cinemática")
@export var tiempo_viaje_ida: float = 1.2
@export var tiempo_pausa_mirando: float = 1.1
@export var tiempo_viaje_vuelta: float = 0.8
@export var zoom_acercamiento: Vector2 = Vector2(1.4, 1.4)

@export_group("Persecución")
# Lino corre a 230: tiene que poder escaparse
@export var velocidad_de_persecucion: float = 145.0
@export var ventaja_minima: float = 650.0
@export var espera_maxima: float = 4.0

var secuencia_activada: bool = false
var vacio_quieto: bool = false
var proximo_polvo: float = 0.0


func _process(delta: float) -> void:
	if not vacio_quieto or not is_instance_valid(enemigo_vacio):
		return
	proximo_polvo -= delta
	if proximo_polvo <= 0.0:
		proximo_polvo = PAUSA_ENTRE_POLVOS
		enemigo_vacio.call("_emit_particles")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or secuencia_activada:
		return

	secuencia_activada = true
	var paso_del_vacio: Node = enemigo_vacio.get("path_walk_behavior")
	if paso_del_vacio:
		paso_del_vacio.process_mode = Node.PROCESS_MODE_DISABLED
	_permitir_captura(false)
	vacio_quieto = true

	if body.has_method("take_control"):
		body.take_control(self)
	body.velocity = Vector2.ZERO

	var camara := get_viewport().get_camera_2d()
	var zoom_original := camara.zoom
	var suavizado_original := camara.position_smoothing_enabled
	camara.position_smoothing_enabled = false

	var cinematica := _mirar_al_vacio(camara, body, zoom_original)
	await cinematica.finished

	camara.position_smoothing_enabled = suavizado_original
	camara.global_position = body.global_position

	if body.has_method("return_control"):
		body.return_control(self)

	await _soltar_al_vacio(body)


func _mirar_al_vacio(camara: Camera2D, body: Node2D, zoom_original: Vector2) -> Tween:
	var cinematica := create_tween()
	(
		cinematica
		. tween_property(camara, "global_position", enemigo_vacio.global_position, tiempo_viaje_ida)
		. set_trans(Tween.TRANS_SINE)
	)
	cinematica.parallel().tween_property(camara, "zoom", zoom_acercamiento, tiempo_viaje_ida)
	cinematica.tween_callback(_dar_alerta)
	cinematica.tween_interval(tiempo_pausa_mirando)
	(
		cinematica
		. tween_property(camara, "global_position", body.global_position, tiempo_viaje_vuelta)
		. set_trans(Tween.TRANS_QUAD)
	)
	cinematica.parallel().tween_property(camara, "zoom", zoom_original, tiempo_viaje_vuelta)
	return cinematica


func _dar_alerta() -> void:
	var alerta: AnimationPlayer = enemigo_vacio.get("alert_animation")
	if alerta:
		alerta.play(&"alert")


func _soltar_al_vacio(body: Node2D) -> void:
	var velocidad: float = (
		velocidad_de_persecucion
		* ElHiloQueNoTejiState.alivio_por_muertes(
			"sequence_puzzle", FRENO_POR_MUERTE, VELOCIDAD_MINIMA
		)
	)
	var seguimiento: Node = enemigo_vacio.get("follow_walk_behavior")
	if seguimiento and seguimiento.get("speeds"):
		seguimiento.speeds.walk_speed = velocidad
	var distancia: float = enemigo_vacio.global_position.distance_to(body.global_position)
	var espera := clampf((ventaja_minima - distancia) / velocidad, 0.0, espera_maxima)
	if espera > 0.0:
		await get_tree().create_timer(espera, false).timeout
	vacio_quieto = false
	if is_instance_valid(enemigo_vacio) and enemigo_vacio.has_method("start"):
		enemigo_vacio.start(body)
	_permitir_captura(true)


func _permitir_captura(permitir: bool) -> void:
	var captura := enemigo_vacio.get_node_or_null("PlayerCaptureArea") as Area2D
	if captura:
		captura.set_deferred("monitoring", permitir)
