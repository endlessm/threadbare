# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## La protección de Luto sobre Lino: un círculo de puntadas en el suelo que marca hasta dónde
## llega su ayuda, y un halo suave sobre el cuerpo. Los dos se avivan poco a poco cuando hay
## proyectiles frenándose, sin saltos, para que con varios a la vez no parpadee.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const COLOR := Color(0.62, 0.82, 1.0, 1.0)
const ALTURA_DEL_CUERPO: float = -28.0

const PUNTADAS: int = 30
const PARTE_DE_CADA_PUNTADA: float = 0.55
const GROSOR_DE_LA_PUNTADA: float = 3.0
const SEGMENTOS_POR_PUNTADA: int = 6
const OPACIDAD_DE_LA_PUNTADA: float = 0.7
const OPACIDAD_DEL_RELLENO: float = 0.05

const TAMANO_TEXTURA_HALO: int = 256
const ESCALA_DEL_HALO := Vector2(0.7, 0.7)
const BRILLO_DEL_HALO: float = 0.17
const BRILLO_EXTRA_DEL_HALO: float = 0.13

## Cuánto se apaga el círculo cuando no hay proyectiles frenándose, y cuánto se aviva con ellos.
const VISIBILIDAD_EN_REPOSO: float = 0.45
const VISIBILIDAD_ACTIVA: float = 1.0
## Con tantos proyectiles frenándose la protección ya está al máximo.
const PROYECTILES_PARA_EL_MAXIMO: int = 3
const SUAVIDAD: float = 4.0
const DURACION_APARECER: float = 0.9
const DURACION_DESAPARECER: float = 1.4

const CANTIDAD_DE_MOTAS: int = 18
const VIDA_DE_LAS_MOTAS: float = 1.4
const RADIO_DE_EMISION_DE_MOTAS: float = 30.0
const GRAVEDAD_DE_LAS_MOTAS := Vector2(0, -35)

## Hasta dónde llega la protección; lo fija quien la crea.
var radio: float = 260.0

var _halo: Sprite2D
var _presencia: float = 0.0
var _objetivo_de_presencia: float = 1.0
var _avivado: float = 0.0
var _objetivo_avivado: float = 0.0
var _desapareciendo: bool = false


func _ready() -> void:
	# Se dibuja detrás de Lino, a sus pies, y no tapa a los proyectiles.
	show_behind_parent = true

	_halo = Sprite2D.new()
	_halo.texture = AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO)
	_halo.material = AyudasDeEscena.material_de_suma()
	_halo.scale = ESCALA_DEL_HALO
	_halo.position = Vector2(0, ALTURA_DEL_CUERPO)
	_halo.modulate = Color(COLOR, 0.0)
	add_child(_halo)
	self_modulate.a = 0.0
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radio, Color(COLOR, OPACIDAD_DEL_RELLENO))
	var paso: float = TAU / PUNTADAS
	for i in PUNTADAS:
		var inicio: float = i * paso
		draw_arc(
			Vector2.ZERO,
			radio,
			inicio,
			inicio + paso * PARTE_DE_CADA_PUNTADA,
			SEGMENTOS_POR_PUNTADA,
			Color(COLOR, OPACIDAD_DE_LA_PUNTADA),
			GROSOR_DE_LA_PUNTADA,
			true
		)


func _process(delta: float) -> void:
	var velocidad: float = 1.0 - exp(-SUAVIDAD * delta)
	_avivado = lerpf(_avivado, _objetivo_avivado, velocidad)
	var duracion: float = DURACION_DESAPARECER if _desapareciendo else DURACION_APARECER
	_presencia = move_toward(_presencia, _objetivo_de_presencia, delta / duracion)

	var visibilidad: float = lerpf(VISIBILIDAD_EN_REPOSO, VISIBILIDAD_ACTIVA, _avivado)
	self_modulate.a = visibilidad * _presencia
	_halo.modulate.a = (BRILLO_DEL_HALO + BRILLO_EXTRA_DEL_HALO * _avivado) * _presencia

	if _desapareciendo and _presencia <= 0.0:
		queue_free()


## Cuántos proyectiles se están frenando ahora mismo.
func frenando(cantidad: int) -> void:
	_objetivo_avivado = clampf(float(cantidad) / PROYECTILES_PARA_EL_MAXIMO, 0.0, 1.0)


func soltar_motas() -> void:
	var motas := _crear_motas()
	motas.position = Vector2(0, ALTURA_DEL_CUERPO)
	add_child(motas)
	motas.emitting = true
	motas.finished.connect(motas.queue_free)


func desvanecer() -> void:
	_desapareciendo = true
	_objetivo_de_presencia = 0.0
	_objetivo_avivado = 0.0


func _crear_motas() -> CPUParticles2D:
	var motas := CPUParticles2D.new()
	motas.material = AyudasDeEscena.material_de_suma()
	motas.amount = CANTIDAD_DE_MOTAS
	motas.lifetime = VIDA_DE_LAS_MOTAS
	motas.one_shot = true
	motas.explosiveness = 0.3
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motas.emission_sphere_radius = RADIO_DE_EMISION_DE_MOTAS
	motas.direction = Vector2.UP
	motas.spread = 25.0
	motas.gravity = GRAVEDAD_DE_LAS_MOTAS
	motas.initial_velocity_min = 20.0
	motas.initial_velocity_max = 50.0
	motas.scale_amount_min = 3.0
	motas.scale_amount_max = 5.0
	motas.color = COLOR
	return motas
