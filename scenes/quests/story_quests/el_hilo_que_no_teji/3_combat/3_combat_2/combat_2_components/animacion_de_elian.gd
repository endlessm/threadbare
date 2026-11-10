# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name AnimacionDeElian
extends RefCounted
## Tiempos de animación de Elián, más lentos que los de las sombras pequeñas.
## Elián usa la misma escena (y las mismas animaciones) que las sombras pequeñas,
## así que aquí se le hacen una copia de "idle" y de "attack" con tiempos propios.
## Todos los tiempos de este archivo están en segundos.

const ANIM_ANTICIPACION: StringName = &"attack anticipation"
## Cuánto dura cada cuadro del idle (0.28 s), y qué cuadros del sprite se usan.
const SEGUNDOS_POR_CUADRO_IDLE: float = 0.28
const CUADROS_IDLE: Array[int] = [0, 1, 2, 3]
## El ataque paso a paso: [animación del sprite, número de cuadro, segundos que se queda].
## Primero se agacha (anticipación), luego dispara (attack) y al final vuelve a levantarse.
const ATAQUE: Array = [
	[ANIM_ANTICIPACION, 0, 0.22],
	[ANIM_ANTICIPACION, 1, 0.22],
	[ANIM_ANTICIPACION, 2, 0.22],
	[ANIM_ANTICIPACION, 3, 0.22],
	[ANIM_ATAQUE, 0, 0.12],
	[ANIM_ATAQUE, 1, 0.12],
	[ANIM_ATAQUE, 2, 0.16],
	[ANIM_ATAQUE, 3, 0.3],
	[ANIM_ANTICIPACION, 2, 0.16],
	[ANIM_ANTICIPACION, 1, 0.16],
	[ANIM_ANTICIPACION, 0, 0.2],
]
## Posición dentro de ATAQUE (empieza en 0) donde sale el proyectil: el tercer cuadro de
## "attack". Las llamadas de lanzamiento que ya trae la animación se mueven a ese momento.
const PASO_DEL_LANZAMIENTO: int = 6

## El AnimatedSprite2D avanza solo sus cuadros: se repite el cuadro para fijarlo.
const REPETIR_CUADRO_CADA: float = 0.05
## Evita que, por redondeo de floats, se cuele una clave de más al final de un cuadro.
const MARGEN_DE_TIEMPO: float = 0.001

const PISTA_ANIMACION := NodePath("AnimatedSprite2D:animation")
const PISTA_CUADRO := NodePath("AnimatedSprite2D:frame")
## Nombre del nodo que se le agrega a Elián para que mire a Lino (ver clase Mirada).
const MIRADA: StringName = &"MiradaDeElian"
const BIBLIOTECA: StringName = &""
const ANIM_IDLE: StringName = &"idle"
const ANIM_ATAQUE: StringName = &"attack"
const RUTA_REPRODUCTOR: NodePath = ^"%AnimationPlayer"
const GRUPO_JUGADOR: StringName = &"player"


## Cambia las animaciones de este Elián para que sean más lentas y para que se voltee
## hacia Lino antes de atacar. Solo afecta a este Elián, no a las demás sombras.
static func aplicar(elian: Node) -> void:
	var reproductor := elian.get_node_or_null(RUTA_REPRODUCTOR) as AnimationPlayer
	if not reproductor or not reproductor.has_animation_library(BIBLIOTECA):
		return
	# La biblioteca de animaciones es un recurso compartido con todas las sombras pequeñas:
	# si se editara directo, ellas también se volverían lentas. Por eso se duplica.
	var biblioteca := reproductor.get_animation_library(BIBLIOTECA).duplicate() as AnimationLibrary
	var idle := biblioteca.get_animation(ANIM_IDLE).duplicate(true) as Animation
	var ataque := biblioteca.get_animation(ANIM_ATAQUE).duplicate(true) as Animation
	_rehacer_idle(idle)
	_rehacer_ataque(ataque)
	biblioteca.add_animation(ANIM_IDLE, idle)
	biblioteca.add_animation(ANIM_ATAQUE, ataque)
	# Este nodo es el que voltea a Elián hacia Lino; las animaciones lo llaman por nombre.
	var mirada := Mirada.new()
	mirada.name = MIRADA
	mirada.lado = (elian as Node2D).scale.x
	elian.add_child(mirada)
	# Al cambiar la biblioteca el AnimationPlayer deja de reproducir lo que sonaba,
	# así que se guarda la animación actual y se vuelve a lanzar después.
	var actual := reproductor.current_animation
	reproductor.remove_animation_library(BIBLIOTECA)
	reproductor.add_animation_library(BIBLIOTECA, biblioteca)
	if actual:
		reproductor.play(actual)


## Deja a Elián quieto en idle: para el temporizador de sus ataques y cancela el ataque en curso.
static func quedarse_en_reposo(elian: Node) -> void:
	var temporizador := elian.get_node_or_null("Timer") as Timer
	if temporizador:
		temporizador.stop()
	var reproductor := elian.get_node_or_null(RUTA_REPRODUCTOR) as AnimationPlayer
	if reproductor:
		reproductor.play(ANIM_IDLE)
	# _is_attacking es una variable del script de la sombra; se usa set() porque aquí solo
	# se tiene un Node genérico.
	elian.set(&"_is_attacking", false)


static func _rehacer_idle(idle: Animation) -> void:
	var cuadros := _pista(idle, PISTA_CUADRO)
	_vaciar(idle, cuadros)
	idle.value_track_set_update_mode(cuadros, Animation.UPDATE_DISCRETE)
	var tiempo := 0.0
	for cuadro in CUADROS_IDLE:
		_sostener(idle, cuadros, tiempo, SEGUNDOS_POR_CUADRO_IDLE, cuadro)
		tiempo += SEGUNDOS_POR_CUADRO_IDLE
	idle.length = tiempo


static func _rehacer_ataque(ataque: Animation) -> void:
	var nombres := _pista(ataque, PISTA_ANIMACION)
	var cuadros := _pista(ataque, PISTA_CUADRO)
	_vaciar(ataque, nombres)
	_vaciar(ataque, cuadros)
	ataque.value_track_set_update_mode(cuadros, Animation.UPDATE_DISCRETE)
	var tiempo := 0.0
	var lanzamiento := 0.0
	var anterior := &""
	for indice in ATAQUE.size():
		var paso: Array = ATAQUE[indice]
		if paso[0] != anterior:
			ataque.track_insert_key(nombres, tiempo, paso[0])
			anterior = paso[0]
		_sostener(ataque, cuadros, tiempo, paso[2], paso[1])
		if indice == PASO_DEL_LANZAMIENTO:
			lanzamiento = tiempo
		tiempo += paso[2]
	ataque.length = tiempo
	_mover_llamadas_al(ataque, lanzamiento)
	# Va después de la pista de lanzamiento y deshace el giro de la sombra al disparar.
	_agregar_llamada(ataque, 0.0, &"mirar_a_lino")
	_agregar_llamada(ataque, lanzamiento, &"mantener")


static func _mover_llamadas_al(animacion: Animation, tiempo: float) -> void:
	for pista in animacion.get_track_count():
		if animacion.track_get_type(pista) != Animation.TYPE_METHOD:
			continue
		for clave in animacion.track_get_key_count(pista):
			animacion.track_set_key_time(pista, clave, tiempo)


static func _agregar_llamada(animacion: Animation, tiempo: float, metodo: StringName) -> void:
	var pista := animacion.add_track(Animation.TYPE_METHOD)
	animacion.track_set_path(pista, NodePath(MIRADA))
	animacion.track_insert_key(pista, tiempo, {"method": metodo, "args": []})


static func _sostener(
	animacion: Animation, pista: int, desde: float, duracion: float, cuadro: int
) -> void:
	var tiempo := 0.0
	while tiempo < duracion - MARGEN_DE_TIEMPO:
		animacion.track_insert_key(pista, desde + tiempo, cuadro)
		tiempo += REPETIR_CUADRO_CADA


static func _pista(animacion: Animation, ruta: NodePath) -> int:
	var pista := animacion.find_track(ruta, Animation.TYPE_VALUE)
	if pista < 0:
		pista = animacion.add_track(Animation.TYPE_VALUE)
		animacion.track_set_path(pista, ruta)
	return pista


static func _vaciar(animacion: Animation, pista: int) -> void:
	while animacion.track_get_key_count(pista) > 0:
		animacion.track_remove_key(pista, 0)


## Voltea a Elián hacia Lino. Lo llaman las pistas de la animación "attack" (ver _rehacer_ataque).
class Mirada:
	extends Node

	## Valor de scale.x con el que Elián debe quedarse: 1 mira a la izquierda, -1 a la derecha.
	var lado: float = 1.0

	func mirar_a_lino() -> void:
		var elian := get_parent() as Node2D
		var lino := get_tree().get_first_node_in_group(GRUPO_JUGADOR) as Node2D
		if lino:
			lado = 1.0 if lino.global_position.x < elian.global_position.x else -1.0
		elian.scale.x = lado

	func mantener() -> void:
		(get_parent() as Node2D).scale.x = lado
