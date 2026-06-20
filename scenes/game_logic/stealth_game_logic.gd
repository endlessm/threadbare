# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

# AÑADE ESTA LÍNEA AQUÍ PARA SOLUCIONAR EL ERROR DEL MAGO
@export var recurso_dialogo: DialogueResource 

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)

func _on_player_detected(player: Node2D) -> void:
	if player.has_method("defeat"):
		# player.defeat()  <-- COMENTADA PARA EVITAR EL ERROR
		pass 
	else:
		push_warning("Detected node does not have defeat() method", player)

func _on_mago_body_entered(body: Node2D) -> void:
	if body.name == "Bell":
		DialogueManager.show_example_dialogue_balloon(recurso_dialogo, "inicio_guardian")
	else:
		print("El objeto que entró se llama: ", body.name)
