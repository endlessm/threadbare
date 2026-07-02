# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
@export_file("*.tscn") var next_scene: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

func cambiar_escena(item):
	if next_scene:
		print("CAMBIANDO ESCENA")
		await DialogueManager.dialogue_ended
		GameState.set_challenge_start_scene(next_scene)
		SceneSwitcher.change_to_file_with_transition(next_scene)	
	
