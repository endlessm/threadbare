# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label
## Contador de fragmentos de hilo del nivel.

const HILOS_POR_NIVEL: int = 3

# Estáticas para que sobrevivan cuando el nivel se recarga al morir.
static var base_hilos_nivel: int = -1
static var ultima_escena_cargada: String = ""


func _ready() -> void:
	var escena_actual := get_tree().current_scene.scene_file_path
	if escena_actual != ultima_escena_cargada:
		ultima_escena_cargada = escena_actual
		base_hilos_nivel = ElHiloQueNoTejiState.hilos_recogidos


func _process(_delta: float) -> void:
	var fragmentos_en_este_nivel := ElHiloQueNoTejiState.hilos_recogidos - base_hilos_nivel
	var mostrados := clampi(fragmentos_en_este_nivel, 0, HILOS_POR_NIVEL)
	text = "%d/%d" % [mostrados, HILOS_POR_NIVEL]
