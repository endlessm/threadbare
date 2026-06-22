# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label

var hilos_al_iniciar_escena: int = 0

func _ready() -> void:
	# Guardamos cuántos hilos globales traía el jugador al entrar a este minijuego (ej: 3)
	hilos_al_iniciar_escena = ElHiloQueNoTejiState.hilos_recogidos

func _process(_delta: float) -> void:
	var hilos_actuales = ElHiloQueNoTejiState.hilos_recogidos
	
	# Restamos el total global menos los que ya traíamos de niveles anteriores.
	# Así la matemática se reinicia a 0 visualmente para ESTA escena.
	var fragmentos_en_este_nivel = hilos_actuales - hilos_al_iniciar_escena
	
	if fragmentos_en_este_nivel == 0:
		text = "0/3"
	elif fragmentos_en_este_nivel >= 3:
		# Si ya recogimos los 3 de esta zona, se queda fijo en 3/3
		text = "3/3"
	else:
		# Si recogimos 1 o 2
		text = str(fragmentos_en_este_nivel) + "/3"
