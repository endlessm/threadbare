# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BrilloDelCollar
extends Node2D
## Brillo del collar de Lino cuando hay un hilo cerca.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const POSICION_DE_LA_MANO := Vector2(21, 4)
const DISTANCIA_INICIO: float = 460.0
const DISTANCIA_MAXIMA: float = 110.0
const COLOR := Color(1.0, 0.92, 0.6)
const TAMANO: float = 0.34
const TAMANO_TEXTURA: int = 96
const SEGUNDOS_ENTRE_BUSQUEDAS: float = 0.5
const VELOCIDAD_DEL_BRILLO: float = 1.5
const OPACIDAD_MAXIMA: float = 0.9
const LATIDO_MINIMO: float = 0.75
const LATIDO_AMPLITUD: float = 0.25
const FRECUENCIA_LATIDO_TENUE: float = 3.0
const FRECUENCIA_LATIDO_FUERTE: float = 9.0
const TAMANO_EN_REPOSO: float = 0.85
const TAMANO_POR_LATIDO: float = 0.3
const SPRITE_DEL_JUGADOR: String = "%PlayerSprite"

var halo: Sprite2D
var hilos: Array[Node2D] = []
var proxima_busqueda: float = 0.0
var tiempo: float = 0.0
var fuerza: float = 0.0


func _ready() -> void:
	halo = Sprite2D.new()
	halo.texture = AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA)
	halo.material = AyudasDeEscena.material_de_suma()
	halo.modulate = Color(COLOR, 0.0)
	halo.scale = Vector2.ONE * TAMANO
	halo.z_index = 1
	add_child(halo)


func _process(delta: float) -> void:
	tiempo += delta
	proxima_busqueda -= delta
	if proxima_busqueda <= 0.0:
		proxima_busqueda = SEGUNDOS_ENTRE_BUSQUEDAS
		_buscar_hilos()

	var objetivo := 1.0 - smoothstep(DISTANCIA_MAXIMA, DISTANCIA_INICIO, _distancia_al_hilo())
	fuerza = move_toward(fuerza, objetivo, delta * VELOCIDAD_DEL_BRILLO)
	_dibujar_halo()


func _distancia_al_hilo() -> float:
	var mas_cerca := INF
	for hilo in hilos:
		if is_instance_valid(hilo) and hilo.is_visible_in_tree() and hilo.get("revealed"):
			mas_cerca = minf(mas_cerca, global_position.distance_to(hilo.global_position))
	return mas_cerca


func _dibujar_halo() -> void:
	var sprite := get_parent().get_node_or_null(SPRITE_DEL_JUGADOR) as AnimatedSprite2D
	var lado := -1.0 if sprite and sprite.flip_h else 1.0
	halo.position = Vector2(POSICION_DE_LA_MANO.x * lado, POSICION_DE_LA_MANO.y)
	var frecuencia := lerpf(FRECUENCIA_LATIDO_TENUE, FRECUENCIA_LATIDO_FUERTE, fuerza)
	var latido := LATIDO_MINIMO + LATIDO_AMPLITUD * sin(tiempo * frecuencia)
	halo.modulate.a = fuerza * latido * OPACIDAD_MAXIMA
	halo.scale = Vector2.ONE * TAMANO * (TAMANO_EN_REPOSO + TAMANO_POR_LATIDO * fuerza * latido)


func _buscar_hilos() -> void:
	hilos.clear()
	var escena := get_tree().current_scene
	if not escena:
		return
	for nodo in escena.find_children("*", "", true, false):
		if nodo is StealthCollectible:
			hilos.append(nodo)
