# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## La bendición de Lázaro: ayuda a Lino si pasa mucho tiempo sin llenar un jarrón.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const TIEMPO_SIN_LLENAR: float = 60.0
const DISTANCIA_PUENTE_CRUZADO: float = 900.0
## dialogos_bendiciones.dialogue
const DIALOGO: DialogueResource = preload("../dialogues/dialogos_bendiciones.dialogue")
const TITULO_DIALOGO: String = "bendicion"
const COLOR_LUZ := Color(1.0, 0.88, 0.5, 1.0)
const DURACION_LUZ: float = 2.4
const PARTE_DE_LA_LUZ_ANTES_DE_AYUDAR: float = 0.6
const PARTE_DE_LA_LUZ_QUE_SUBE: float = 0.3
const BRILLO_MAXIMO_DEL_HALO: float = 0.85
const TAMANO_TEXTURA_HALO: int = 256
const ESCALA_INICIAL_HALO := Vector2(0.3, 0.3)
const ESCALA_FINAL_HALO := Vector2(1.5, 1.5)
const Z_INDEX_DE_LA_LUZ: int = 5
const CANTIDAD_DE_MOTAS: int = 28
const VIDA_DE_LAS_MOTAS: float = 1.6
const EXPLOSIVIDAD_DE_LAS_MOTAS: float = 0.35
const RADIO_DE_EMISION: float = 34.0
const DISPERSION_DE_LAS_MOTAS: float = 25.0
const GRAVEDAD_DE_LAS_MOTAS := Vector2(0, -40)
const VELOCIDAD_MINIMA_DE_LAS_MOTAS: float = 30.0
const VELOCIDAD_MAXIMA_DE_LAS_MOTAS: float = 70.0
const TAMANO_MINIMO_DE_LAS_MOTAS: float = 3.0
const TAMANO_MAXIMO_DE_LAS_MOTAS: float = 6.0

# static: una vez dada, no se repite al recargar el nivel. Se guarda por nivel (el nombre
# que se pone en "nivel"), para que lo concedido en un nivel no cuente en el otro.
static var _concedida_en: Dictionary = {}
## Segundos sin llenar un jarrón, por nivel. Se sigue contando aunque Lino se deshile.
static var _tiempo_en: Dictionary = {}

var jugador: Node2D
## Nombre con el que este nivel guarda su estado, el mismo que usa para contar sus muertes.
var nivel: String
var flecha: Node
var elian: Node2D

var _en_dialogo: bool = false


## Borra lo guardado de un nivel, para cuando empieza una partida nueva.
static func olvidar(nivel_a_olvidar: String) -> void:
	_concedida_en.erase(nivel_a_olvidar)
	_tiempo_en.erase(nivel_a_olvidar)


func _ready() -> void:
	if _concedida_en.get(nivel, false):
		_activar_ayudas()
	if DialogueManager.has_signal("dialogue_started"):
		DialogueManager.dialogue_started.connect(
			func(_recurso: Resource) -> void: _en_dialogo = true
		)
	DialogueManager.dialogue_ended.connect(func(_recurso: Resource) -> void: _en_dialogo = false)


func reiniciar_cuenta() -> void:
	_tiempo_en[nivel] = 0.0


func _process(delta: float) -> void:
	if _concedida_en.get(nivel, false) or not is_instance_valid(jugador):
		return
	_tiempo_en[nivel] = _tiempo_en.get(nivel, 0.0) + delta
	if _tiempo_en[nivel] < TIEMPO_SIN_LLENAR and not _cruzo_el_puente():
		return
	if _en_dialogo or jugador.mode != jugador.Mode.USER_CONTROLLED:
		return
	_conceder()


func _cruzo_el_puente() -> bool:
	return (
		is_instance_valid(elian)
		and elian.global_position.distance_to(jugador.global_position) < DISTANCIA_PUENTE_CRUZADO
	)


func _conceder() -> void:
	_concedida_en[nivel] = true
	_decir_desde_lejos()
	_envolver_en_luz()
	await get_tree().create_timer(DURACION_LUZ * PARTE_DE_LA_LUZ_ANTES_DE_AYUDAR).timeout
	_activar_ayudas()


func _decir_desde_lejos() -> void:
	await AyudasDeEscena.mostrar_globo_arriba(DIALOGO, TITULO_DIALOGO)


func _activar_ayudas() -> void:
	if is_instance_valid(flecha):
		flecha.activa = true


func _envolver_en_luz() -> void:
	var textura := AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO)
	var suma := AyudasDeEscena.material_de_suma()

	var luz := Node2D.new()
	luz.z_index = Z_INDEX_DE_LA_LUZ
	jugador.add_child(luz)

	var halo := Sprite2D.new()
	halo.texture = textura
	halo.material = suma
	halo.modulate = Color(COLOR_LUZ, 0.0)
	halo.scale = ESCALA_INICIAL_HALO
	luz.add_child(halo)

	var motas := _crear_motas(suma)
	luz.add_child(motas)
	motas.emitting = true

	luz.create_tween().tween_property(halo, "scale", ESCALA_FINAL_HALO, DURACION_LUZ).set_ease(
		Tween.EASE_OUT
	)
	var brillar := luz.create_tween()
	brillar.tween_property(
		halo, "modulate:a", BRILLO_MAXIMO_DEL_HALO, DURACION_LUZ * PARTE_DE_LA_LUZ_QUE_SUBE
	)
	brillar.tween_property(halo, "modulate:a", 0.0, DURACION_LUZ * (1.0 - PARTE_DE_LA_LUZ_QUE_SUBE))
	brillar.tween_callback(luz.queue_free)


func _crear_motas(material_de_suma: CanvasItemMaterial) -> CPUParticles2D:
	var motas := CPUParticles2D.new()
	motas.material = material_de_suma
	motas.amount = CANTIDAD_DE_MOTAS
	motas.lifetime = VIDA_DE_LAS_MOTAS
	motas.one_shot = true
	motas.explosiveness = EXPLOSIVIDAD_DE_LAS_MOTAS
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motas.emission_sphere_radius = RADIO_DE_EMISION
	motas.direction = Vector2.UP
	motas.spread = DISPERSION_DE_LAS_MOTAS
	motas.gravity = GRAVEDAD_DE_LAS_MOTAS
	motas.initial_velocity_min = VELOCIDAD_MINIMA_DE_LAS_MOTAS
	motas.initial_velocity_max = VELOCIDAD_MAXIMA_DE_LAS_MOTAS
	motas.scale_amount_min = TAMANO_MINIMO_DE_LAS_MOTAS
	motas.scale_amount_max = TAMANO_MAXIMO_DE_LAS_MOTAS
	motas.color = COLOR_LUZ
	return motas
