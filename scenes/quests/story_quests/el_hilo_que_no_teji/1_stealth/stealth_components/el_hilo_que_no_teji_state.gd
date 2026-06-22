# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ElHiloQueNoTejiState
extends RefCounted

# Variables estáticas que sobreviven al cambio de escena
static var hilos_recogidos: int = 0
static var player_saturation: float = 0.0
static var world_saturation: float = 0.0

const MAX_HILOS_MUNDO: int = 9
const PLAYER_SAT_INCREMENT: float = 16.66
const WORLD_SAT_INCREMENT_SMALL: float = 1.875 # Aumento lento para los primeros 8 hilos

static func recolectar_hilo() -> void:
	if hilos_recogidos < MAX_HILOS_MUNDO:
		hilos_recogidos += 1
		
		# --- SATURACIÓN DEL JUGADOR ---
		# El jugador suma 16.66% por hilo. Al llegar al hilo 6, llega a 100%.
		player_saturation = clamp(player_saturation + PLAYER_SAT_INCREMENT, 0.0, 100.0)
		
		# --- SATURACIÓN DEL MUNDO ---
		if hilos_recogidos < 9:
			# Del hilo 1 al 8, el mundo sube solo 3.75% por cada uno
			world_saturation = clamp(world_saturation + WORLD_SAT_INCREMENT_SMALL, 0.0, 100.0)
		elif hilos_recogidos == 9:
			# En el hilo 9 (el clímax), el mundo recupera todo el color de golpe a 100%
			world_saturation = 100.0
		
		print("Hilo recogido! Total: ", hilos_recogidos)
		print("Sat Jugador: ", player_saturation, "% | Sat Mundo: ", world_saturation, "%")
	else:
		print("Todos los 9 hilos recogidos. Límite de saturación alcanzado.")

# Función de apoyo por si necesitas reiniciar el nivel desde cero
static func resetear_saturacion() -> void:
	hilos_recogidos = 0
	player_saturation = 0.0
	world_saturation = 0.0
