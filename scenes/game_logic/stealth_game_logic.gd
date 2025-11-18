# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool # Permite que el script se ejecute en el editor de Godot (útil para herramientas).
class_name StealthGameLogic # Le da un nombre único: "Lógica del Juego de Sigilo".
extends Node # Es un nodo base, un objeto que organiza la lógica.


# --- Inicialización del Script ---

# Se ejecuta al inicio, cuando el nodo está listo en la escena.
func _ready() -> void:
	# Si solo estamos viendo el editor (no jugando), se detiene aquí.
	if Engine.is_editor_hint():
		return 
	
	# Bucle que revisa a todos los objetos llamados "guard_enemy" (los guardias).
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		# CONEXIÓN: Este es el paso clave. 
		# Le dice al sistema: "Cuando este 'guard' emita la SEÑAL 'player_detected', 
		# quiero que se ejecute la función '_on_player_detected' de este script."
		guard.player_detected.connect(self._on_player_detected)


# --- Manejo de la Detección (Receptor de la Señal) ---

# Esta función es el "teléfono" que suena cuando un guardia EMITE la señal de detección.
# Recibe como información al objeto 'player' (el jugador detectado).
func _on_player_detected(player: Player) -> void:
	# Llama a la función 'defeat()' del jugador. 
	# Esto inicia la secuencia de derrota (Game Over).
	player.defeat()
