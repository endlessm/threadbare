# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## La bendición de Luto: tras dos deshilados, aparece como fantasma y frena los proyectiles.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const MUERTES_PARA_LA_BENDICION: int = 2
const TITULO_DIALOGO: String = "bendicion_de_luto"
## dialogos_bendiciones.dialogue
const DIALOGO: DialogueResource = preload("../dialogues/dialogos_bendiciones.dialogue")
const PENSAMIENTO_DE_LINO: String = "Luto... tú tampoco quieres que me pierda aquí, ¿verdad?"
const RUTA_GLOBO_DE_LINO: NodePath = ^"HUD/PanelContainer"
## luto.tres
const FIGURA_DE_LUTO: SpriteFrames = preload("uid://crrr8ncum86vx")
const LUGARES_PARA_LUTO: Array[Vector2] = [
	Vector2(-80, 0),
	Vector2(80, 0),
	Vector2(-70, 45),
	Vector2(70, 45),
	Vector2(0, 75),
	Vector2(-110, -15),
	Vector2(110, -15),
]
# Capa de colisión 512: solo Lino la tiene en su máscara (son las orillas del lago)
const CAPAS_DE_PARED: int = 1 | 16 | 512
const RADIO_DE_LUTO: float = 22.0
const PIES_DE_LUTO: float = 40.0
const OPACIDAD_DE_LUTO: float = 0.8
const DURACION_APARECER: float = 0.5
const DURACION_DESAPARECER: float = 0.9
const ESPERA_ANTES_DE_IRSE: float = 2.5
const LADRIDOS: int = 3
const MAXIMO_DE_LADRIDOS: int = 1
const ANIM_QUIETO: StringName = &"idle"
const ANIM_LADRAR: StringName = &"bark"
const PAUSA_ENTRE_LADRIDOS: float = 0.38
const ESPERA_INICIAL: float = 1.5
const DISTANCIA_DE_FRENADO: float = 260.0
const VELOCIDAD_AL_FRENAR: float = 0.65
const TIEMPO_DE_FRENADO: float = 0.35
const GRUPO_PROYECTILES: StringName = &"projectiles"
const META_VELOCIDAD: StringName = &"velocidad_antes_de_luto"

# Por nivel: en qué partida (numero_partida) se anunció. Así no se repite al reintentar el
# nivel, pero sí en otra partida, y lo anunciado en un nivel no cuenta en el otro.
static var _anunciada_en: Dictionary = {}

var jugador: Node2D
## Nombre con el que este nivel cuenta sus muertes en ElHiloQueNoTejiState.
var nivel: String

var _en_dialogo: bool = false
var _espera: float = ESPERA_INICIAL


func _ready() -> void:
	if ElHiloQueNoTejiState.muertes_en(nivel) < MUERTES_PARA_LA_BENDICION:
		set_process(false)
		set_physics_process(false)
		return
	if DialogueManager.has_signal("dialogue_started"):
		DialogueManager.dialogue_started.connect(
			func(_recurso: Resource) -> void: _en_dialogo = true
		)
	DialogueManager.dialogue_ended.connect(func(_recurso: Resource) -> void: _en_dialogo = false)


func _process(delta: float) -> void:
	if _anunciada_en.get(nivel, -1) == ElHiloQueNoTejiState.numero_partida:
		set_process(false)
		return
	_espera -= delta
	if _espera > 0.0 or _en_dialogo or not is_instance_valid(jugador):
		return
	if jugador.get("mode") != Player.Mode.USER_CONTROLLED:
		return
	_anunciada_en[nivel] = ElHiloQueNoTejiState.numero_partida
	set_process(false)
	_anunciar()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador):
		return
	for proyectil in get_tree().get_nodes_in_group(GRUPO_PROYECTILES):
		var cuerpo := proyectil as RigidBody2D
		if cuerpo:
			_frenar(cuerpo, delta)


func _frenar(cuerpo: RigidBody2D, delta: float) -> void:
	var hacia_lino: Vector2 = jugador.global_position - cuerpo.global_position
	var velocidad: Vector2 = cuerpo.linear_velocity
	# Solo los que vienen hacia Lino: los que él repele se van a su velocidad.
	if hacia_lino.length() > DISTANCIA_DE_FRENADO or velocidad.dot(hacia_lino) <= 0.0:
		return
	var normal: float = maxf(cuerpo.get_meta(META_VELOCIDAD, 0.0), velocidad.length())
	cuerpo.set_meta(META_VELOCIDAD, normal)
	var frenada: float = normal * VELOCIDAD_AL_FRENAR
	if velocidad.length() <= frenada:
		return
	var paso: float = (normal - frenada) * delta / TIEMPO_DE_FRENADO
	cuerpo.linear_velocity = velocidad.normalized() * maxf(velocidad.length() - paso, frenada)


func _anunciar() -> void:
	var luto := _aparecer_luto()
	await AyudasDeEscena.mostrar_globo_arriba(DIALOGO, TITULO_DIALOGO)
	if is_instance_valid(luto):
		luto.play(ANIM_LADRAR)
	for _ladrido in LADRIDOS:
		if not is_instance_valid(jugador):
			return
		var desde := luto.global_position if is_instance_valid(luto) else jugador.global_position
		Ladrido.sonar(self, desde, MAXIMO_DE_LADRIDOS)
		await get_tree().create_timer(PAUSA_ENTRE_LADRIDOS).timeout
	if is_instance_valid(luto):
		luto.play(ANIM_QUIETO)
	if _en_dialogo:
		await DialogueManager.dialogue_ended
	if not is_instance_valid(jugador) or not jugador.owner:
		_desvanecer(luto)
		return
	var globo_de_lino := jugador.owner.get_node_or_null(RUTA_GLOBO_DE_LINO)
	if is_instance_valid(globo_de_lino) and globo_de_lino.has_method("mostrar_pensamiento"):
		globo_de_lino.mostrar_pensamiento(PENSAMIENTO_DE_LINO)
	await get_tree().create_timer(ESPERA_ANTES_DE_IRSE).timeout
	_desvanecer(luto)


func _aparecer_luto() -> AnimatedSprite2D:
	var lugar: Variant = _lugar_libre_junto_a_lino()
	if lugar == null:
		return null
	var luto := AnimatedSprite2D.new()
	luto.sprite_frames = FIGURA_DE_LUTO
	luto.animation = ANIM_QUIETO
	luto.play()
	luto.z_index = jugador.z_index
	jugador.get_parent().add_child(luto)
	luto.global_position = (lugar as Vector2) - Vector2(0, PIES_DE_LUTO)
	luto.flip_h = jugador.global_position.x < luto.global_position.x
	# Sin el parpadeo de EfectoFantasma, que a veces lo deja casi invisible.
	luto.self_modulate.a = OPACIDAD_DE_LUTO
	luto.modulate.a = 0.0
	luto.create_tween().tween_property(luto, "modulate:a", 1.0, DURACION_APARECER)
	return luto


func _lugar_libre_junto_a_lino() -> Variant:
	var espacio := jugador.get_world_2d().direct_space_state
	var pies := CircleShape2D.new()
	pies.radius = RADIO_DE_LUTO
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = pies
	consulta.collision_mask = CAPAS_DE_PARED
	for desplazamiento in LUGARES_PARA_LUTO:
		var lugar := jugador.global_position + desplazamiento
		consulta.transform = Transform2D(0.0, lugar)
		if not espacio.intersect_shape(consulta, 1).is_empty():
			continue
		var rayo := PhysicsRayQueryParameters2D.create(
			jugador.global_position, lugar, CAPAS_DE_PARED
		)
		if jugador is CollisionObject2D:
			rayo.exclude = [(jugador as CollisionObject2D).get_rid()]
		if espacio.intersect_ray(rayo).is_empty():
			return lugar
	return null


func _desvanecer(luto: AnimatedSprite2D) -> void:
	if not is_instance_valid(luto):
		return
	var irse := luto.create_tween()
	irse.tween_property(luto, "modulate:a", 0.0, DURACION_DESAPARECER)
	irse.tween_callback(luto.queue_free)
