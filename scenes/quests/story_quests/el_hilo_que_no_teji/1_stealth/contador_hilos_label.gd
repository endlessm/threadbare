# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label

# Las variables estáticas son inmortales y sobreviven a las recargas por muerte
static var base_hilos_nivel: int = -1
static var ultima_escena_cargada: String = ""

func _ready() -> void:
	# Obtenemos la ruta exacta del minijuego en el que estamos ahora mismo
	var escena_actual = get_tree().current_scene.scene_file_path
	
	# Si la escena actual es diferente a la última registrada, significa que pasamos de nivel
	if escena_actual != ultima_escena_cargada:
		ultima_escena_cargada = escena_actual
		# Tomamos la "foto" de los hilos globales solo al entrar por primera vez al nivel
		base_hilos_nivel = ElHiloQueNoTejiState.hilos_recogidos

func _process(_delta: float) -> void:
	var hilos_actuales = ElHiloQueNoTejiState.hilos_recogidos
	
	# Restamos usando la variable estática que no se borra al morir
	var fragmentos_en_este_nivel = hilos_actuales - base_hilos_nivel
	
	# Blindamos los resultados por si acaso
	if fragmentos_en_este_nivel <= 0:
		text = "0/3"
	elif fragmentos_en_este_nivel >= 3:
		text = "3/3"
	else:
		text = str(fragmentos_en_este_nivel) + "/3"
