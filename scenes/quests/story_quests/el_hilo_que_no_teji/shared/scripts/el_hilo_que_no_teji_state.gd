# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ElHiloQueNoTejiState
extends RefCounted

const HILOS_DEL_MUNDO: int = 9
const COLOR_COMPLETO: float = 100.0
# Color de Lino que gana por cada hilo (de 0 a 100): con 6 hilos llega a ~100
const COLOR_DE_LINO_POR_HILO: float = 16.66
const COLOR_DEL_MUNDO_POR_HILO: float = 1.875

# Todo lo que sigue es estático para que sobreviva al cambio de escena.
static var hilos_recogidos: int = 0
static var player_saturation: float = 0.0
static var world_saturation: float = 0.0

static var hilos_contados: Dictionary = {}

static var ultimo_hilo_por_nivel: Dictionary = {}

static var niveles_visitados: Dictionary = {}

# Número de la partida actual. resetear_saturacion lo sube al empezar una nueva, y así
# cada nivel sabe si lo que tiene guardado es de una partida anterior
static var numero_partida: int = 0
static var partida_por_nivel: Dictionary = {}

static var muertes_por_nivel: Dictionary = {}


static func recolectar_hilo(id_hilo: String) -> void:
	if hilos_contados.has(id_hilo):
		return
	hilos_contados[id_hilo] = true

	if hilos_recogidos >= HILOS_DEL_MUNDO:
		return
	hilos_recogidos += 1
	player_saturation = clampf(player_saturation + COLOR_DE_LINO_POR_HILO, 0.0, COLOR_COMPLETO)
	if hilos_recogidos < HILOS_DEL_MUNDO:
		world_saturation = clampf(world_saturation + COLOR_DEL_MUNDO_POR_HILO, 0.0, COLOR_COMPLETO)
	else:
		world_saturation = COLOR_COMPLETO


static func guardar_ultimo_hilo(escena: String, posicion: Vector2) -> void:
	ultimo_hilo_por_nivel[escena] = posicion


static func obtener_ultimo_hilo(escena: String) -> Variant:
	return ultimo_hilo_por_nivel.get(escena)


static func registrar_carga_de_nivel(escena: String) -> bool:
	var ya_visitado: bool = niveles_visitados.has(escena)
	niveles_visitados[escena] = true
	return ya_visitado


static func es_partida_nueva_para(nivel: String) -> bool:
	var es_nueva: bool = partida_por_nivel.get(nivel, -1) != numero_partida
	partida_por_nivel[nivel] = numero_partida
	muertes_por_nivel[nivel] = 0 if es_nueva else muertes_en(nivel) + 1
	return es_nueva


static func muertes_en(nivel: String) -> int:
	return muertes_por_nivel.get(nivel, 0)


static func alivio_por_muertes(nivel: String, por_muerte: float, minimo: float) -> float:
	return maxf(1.0 - por_muerte * muertes_en(nivel), minimo)


static func resetear_saturacion() -> void:
	hilos_recogidos = 0
	player_saturation = 0.0
	world_saturation = 0.0
	hilos_contados.clear()
	ultimo_hilo_por_nivel.clear()
	niveles_visitados.clear()
	muertes_por_nivel.clear()
	numero_partida += 1
