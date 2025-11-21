# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D

## Dialogue for cinematic scene
@export var dialogue: DialogueResource 

## Animation player
@export var animation_player: AnimationPlayer

## Scene to switch to
@export_file("*.tscn") var next_scene: String

## Optional path inside
@export var spawn_point_path: String


func _ready() -> void:
	# 1. BUSCAMOS A JOZU Y LO CONGELAMOS
	# (Requiere que el nodo Jozu esté en el grupo "player")
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.velocity = Vector2.ZERO # Frenamos en seco
		player.set_physics_process(false) # Desactivamos controles
		
		# Opcional: Poner animación de Idle para que no se quede caminando en el sitio
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")

	# 2. MOSTRAMOS EL DIÁLOGO
	if not GameState.intro_dialogue_shown:
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		GameState.intro_dialogue_shown = true

	# 3. DECISIÓN FINAL
	if next_scene:
		# Si hay siguiente escena, nos vamos (Jozu sigue congelado hasta irse)
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				spawn_point_path,
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)
	else:
		# SI NO hay siguiente escena (es solo un diálogo introductorio en el nivel),
		# descongelamos a Jozu para que pueda jugar.
		if player:
			player.set_physics_process(true)
