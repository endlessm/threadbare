# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Area2D

# Ruta de la siguiente escena a cargar
@export var next_scene_path: String

# Controla si ya se cambió de escena (para evitar múltiples activaciones)
var scene_changed: bool = false

# Se llama en cada frame (solo se deja por compatibilidad)
func _process(_delta: float) -> void:
	pass

# Detecta cuando el cuerpo entra en el área
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not scene_changed:
		scene_changed = true
		change_escene()

# Cambia a la nueva escena
func change_escene() -> void:
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("No se ha asignado una ruta de escena en 'next_scene_path'.")
