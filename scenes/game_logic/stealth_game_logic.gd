# StealthGameLogic.gd

# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

@export_range(0.5, 3.0, 0.1, "or_greater", "or_less") var zoom: float = 1.0:
	set = _set_zoom


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_set_zoom(zoom)
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		# Conectamos la señal 'player_detected' de cada guardia a esta función.
		# La señal debe emitir el nodo que fue detectado.
		guard.player_detected.connect(self._on_player_detected)


func _on_player_detected(detected_node: Node2D) -> void:
	# --- ¡LA CLAVE ESTÁ AQUÍ! ---
	# `detected_node` es el nodo que entró en el área de detección del guardia.
	# Necesitamos asegurarnos de que es nuestro Player antes de intentar cambiar su 'mode'.

	# Paso 1: Asegúrate de que tu script de jugador tenga 'class_name Player'
	# Abre tu script 'Player.gd' y al inicio, debajo de 'extends ...', añade:
	# class_name Player
	# Esto permite que Godot reconozca tu script como un tipo específico.

	# Paso 2: Usa 'is' para verificar el tipo de nodo.
	# Si 'detected_node' es una instancia de tu clase Player...
	if detected_node is Player:
		# Hacemos un 'cast' seguro para tratar el nodo como nuestra clase Player
		# Esto permite acceder a las propiedades específicas de Player, como 'mode'.
		var player_instance: Player = detected_node
		
		player_instance.mode = Player.Mode.DEFEATED
		await get_tree().create_timer(2.0).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		# Esto se ejecutará si el nodo detectado NO es tu jugador (ej. un TileMapLayer).
		# Es útil para depurar o simplemente ignorar colisiones no deseadas.
		# print("DEBUG: Detección ignorada. Nodo detectado no es el jugador:", detected_node.name, " Tipo:", detected_node.get_class())
		pass # No hacemos nada si no es el jugador esperado.


func _set_zoom(new_value: float) -> void:
	zoom = new_value
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	camera.zoom = Vector2.ONE * zoom
