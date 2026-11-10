# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EfectoFantasma
extends Node
## Difumina y hace parpadear a Luto para que parezca un fantasma.

const OPACIDAD_BASE: float = 0.55
const OPACIDAD_AL_DESVANECERSE: float = 0.06
const PAUSA_ENTRE_DESVANECIMIENTOS := Vector2(2.0, 4.5)
const DURACION_DESVANECIMIENTO: float = 2.6
const DURACION_AL_QUITAR: float = 1.2
const AMPLITUD_ONDA_LENTA: float = 0.1
const VELOCIDAD_ONDA_LENTA: float = 2.1
const AMPLITUD_ONDA_RAPIDA: float = 0.05
const VELOCIDAD_ONDA_RAPIDA: float = 7.3
const DESFASE_ONDA_RAPIDA: float = 1.0
const FASE_INICIAL_MAXIMA: float = 10.0
const FIN_DE_LA_SALIDA: float = 0.6
const INICIO_DE_LA_ENTRADA: float = 0.4

var figura: CanvasItem
var tiempo: float = 0.0
var espera: float = 0.0
var desvanecimiento: float = 0.0
var quitando: bool = false


static func quitar_de(nodo: Node) -> void:
	if not is_instance_valid(nodo):
		return
	for hijo in nodo.get_children():
		if hijo is EfectoFantasma:
			hijo.quitar()
		else:
			quitar_de(hijo)


func _ready() -> void:
	figura = _buscar_figura()
	for forma in get_parent().find_children("*", "CollisionShape2D", true, false):
		forma.set_deferred("disabled", true)
	tiempo = randf() * FASE_INICIAL_MAXIMA
	espera = _pausa_aleatoria()
	# sigue parpadeando aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if quitando or not is_instance_valid(figura):
		return
	tiempo += delta
	espera -= delta
	if espera <= 0.0:
		espera = DURACION_DESVANECIMIENTO + _pausa_aleatoria()
		desvanecimiento = 1.0
	desvanecimiento = maxf(desvanecimiento - delta / DURACION_DESVANECIMIENTO, 0.0)

	var opacidad := (
		OPACIDAD_BASE
		+ AMPLITUD_ONDA_LENTA * sin(tiempo * VELOCIDAD_ONDA_LENTA)
		+ AMPLITUD_ONDA_RAPIDA * sin(tiempo * VELOCIDAD_ONDA_RAPIDA + DESFASE_ONDA_RAPIDA)
	)
	var hueco := (
		smoothstep(0.0, INICIO_DE_LA_ENTRADA, desvanecimiento)
		* smoothstep(1.0, FIN_DE_LA_SALIDA, desvanecimiento)
	)
	# self_modulate porque otros scripts le cambian el modulate al sprite
	figura.self_modulate.a = lerpf(opacidad, OPACIDAD_AL_DESVANECERSE, hueco)


func quitar() -> void:
	if quitando:
		return
	quitando = true
	if not is_instance_valid(figura):
		queue_free()
		return
	var volver := create_tween()
	volver.tween_property(figura, "self_modulate:a", 1.0, DURACION_AL_QUITAR)
	volver.tween_callback(queue_free)


func _pausa_aleatoria() -> float:
	return randf_range(PAUSA_ENTRE_DESVANECIMIENTOS.x, PAUSA_ENTRE_DESVANECIMIENTOS.y)


func _buscar_figura() -> CanvasItem:
	var padre := get_parent()
	if padre is AnimatedSprite2D or padre is Sprite2D:
		return padre
	var sprites := padre.find_children("*", "AnimatedSprite2D", true, false)
	if not sprites.is_empty():
		return sprites[0]
	return padre as CanvasItem
