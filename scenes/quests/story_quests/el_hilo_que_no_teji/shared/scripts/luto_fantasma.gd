# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D
## Luto como fantasma: acompaña a Lino, ladra y se va. Al ser un espectro atraviesa las paredes.

## luto.tres
const FIGURA_DE_LUTO: SpriteFrames = preload("uid://crrr8ncum86vx")
const ANIM_QUIETO: StringName = &"idle"
const ANIM_CAMINAR: StringName = &"walk"
const ANIM_LADRAR: StringName = &"bark"

## Distancia de los pies de Luto al centro de la figura.
const PIES: float = 40.0
const DURACION_APARECER: float = 0.5

const DISTANCIA_DE_SEGUIMIENTO: float = 75.0
const VELOCIDAD_MAXIMA: float = 320.0
const AJUSTE_DE_VELOCIDAD: float = 4.0
const VELOCIDAD_PARA_ECHAR_A_ANDAR: float = 30.0
const VELOCIDAD_PARA_PARARSE: float = 12.0
const VELOCIDAD_DE_REFERENCIA: float = 110.0
const MINIMO_DE_VELOCIDAD_DE_ANIMACION: float = 0.8
const MAXIMO_DE_VELOCIDAD_DE_ANIMACION: float = 2.5
const VELOCIDAD_DE_LINO_QUE_CAMBIA_EL_LADO: float = 20.0
const DISTANCIA_PARA_APARECER_DE_NUEVO: float = 900.0

const DISTANCIA_AL_IRSE: float = 320.0
const DURACION_AL_IRSE: float = 1.8
const PARTE_DEL_FUNDIDO_AL_IRSE: float = 0.65
const VELOCIDAD_DE_ANIMACION_AL_IRSE: float = 1.6

var jugador: Node2D

var _siguiendo: bool = true
var _ladrando: bool = false
var _caminando: bool = false
var _lado := Vector2(-0.8, 0.6).normalized()


func _ready() -> void:
	sprite_frames = FIGURA_DE_LUTO
	animation = ANIM_QUIETO
	play()
	# el mismo efecto de fantasma que tiene Luto en el 3.0 y en el final
	add_child(EfectoFantasma.new())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, DURACION_APARECER)


func _physics_process(delta: float) -> void:
	if not _siguiendo or _ladrando or not is_instance_valid(jugador):
		return
	_cambiar_de_lado_si_lino_se_mueve()
	var meta: Vector2 = jugador.global_position + _lado * DISTANCIA_DE_SEGUIMIENTO
	var hacia: Vector2 = meta - _pies()
	var distancia: float = hacia.length()
	if distancia > DISTANCIA_PARA_APARECER_DE_NUEVO:
		global_position = meta - Vector2(0, PIES)
		return

	var velocidad: float = minf(distancia * AJUSTE_DE_VELOCIDAD, VELOCIDAD_MAXIMA)
	if _caminando:
		_caminando = velocidad >= VELOCIDAD_PARA_PARARSE
	else:
		_caminando = velocidad >= VELOCIDAD_PARA_ECHAR_A_ANDAR

	if _caminando:
		global_position += hacia.normalized() * minf(velocidad * delta, distancia)
		flip_h = hacia.x < 0.0
		speed_scale = clampf(
			velocidad / VELOCIDAD_DE_REFERENCIA,
			MINIMO_DE_VELOCIDAD_DE_ANIMACION,
			MAXIMO_DE_VELOCIDAD_DE_ANIMACION
		)
		_poner_animacion(ANIM_CAMINAR)
	else:
		speed_scale = 1.0
		flip_h = jugador.global_position.x < global_position.x
		_poner_animacion(ANIM_QUIETO)


## Pone a Luto en un sitio concreto (los pies) sin que camine hasta allí.
func colocar_en(pies: Vector2) -> void:
	global_position = pies - Vector2(0, PIES)
	flip_h = jugador.global_position.x < global_position.x if is_instance_valid(jugador) else false


func mirar_a_lino() -> void:
	if is_instance_valid(jugador):
		flip_h = jugador.global_position.x < global_position.x


## Ladra y se queda quieto mientras tanto. Solo debe llamarse una vez a la vez.
func ladrar(veces: int, pausa: float, maximo_de_ladridos: int) -> void:
	_ladrando = true
	speed_scale = 1.0
	mirar_a_lino()
	play(ANIM_LADRAR)
	for _ladrido in veces:
		Ladrido.sonar(get_parent(), global_position, maximo_de_ladridos)
		await get_tree().create_timer(pausa).timeout
		if not is_inside_tree():
			return
	play(ANIM_QUIETO)
	_ladrando = false


## Se aleja hacia donde le indican mientras se desvanece, y desaparece.
func irse(direccion: Vector2) -> void:
	_siguiendo = false
	var rumbo: Vector2 = direccion.normalized() if direccion != Vector2.ZERO else Vector2.UP
	flip_h = rumbo.x < 0.0
	speed_scale = VELOCIDAD_DE_ANIMACION_AL_IRSE
	play(ANIM_CAMINAR)
	var marcha := create_tween().set_parallel(true)
	(
		marcha
		. tween_property(
			self, "global_position", global_position + rumbo * DISTANCIA_AL_IRSE, DURACION_AL_IRSE
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		marcha
		. tween_property(self, "modulate:a", 0.0, DURACION_AL_IRSE * PARTE_DEL_FUNDIDO_AL_IRSE)
		. set_delay(DURACION_AL_IRSE * (1.0 - PARTE_DEL_FUNDIDO_AL_IRSE))
	)
	await marcha.finished
	queue_free()


func _pies() -> Vector2:
	return global_position + Vector2(0, PIES)


## Se coloca detrás de Lino según hacia dónde camina, y conserva el lado cuando él se para.
func _cambiar_de_lado_si_lino_se_mueve() -> void:
	var velocidad: Variant = jugador.get("velocity")
	if not velocidad is Vector2:
		return
	var camino := velocidad as Vector2
	if camino.length() > VELOCIDAD_DE_LINO_QUE_CAMBIA_EL_LADO:
		_lado = -camino.normalized()


func _poner_animacion(nombre: StringName) -> void:
	if animation != nombre:
		play(nombre)
