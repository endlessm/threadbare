# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
@export_file("*.tscn") var next_scene: String
@export var balder_presente:Node2D
@export var animacion:AnimationPlayer
@export var dialogo_final:DialogueResource	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

func cambiar_escena(item):
	if next_scene:
		print("CAMBIANDO ESCENA")
		await DialogueManager.dialogue_ended
		GameState.set_challenge_start_scene(next_scene)
		SceneSwitcher.change_to_file_with_transition(next_scene)	
	
	
func animacion_final()->void:
	%BalderCinematica.visible=true
	%Player.take_control(self)
	%Player.velocity = Vector2.ZERO
	%Player.player_sprite.play("idle")
	%Player.player_sprite.flip_h = true
	animacion.play("final")
	await get_tree().create_timer(3).timeout
	animacion.pause()
	DialogueManager.show_dialogue_balloon(dialogo_final, "", [self])
	await DialogueManager.dialogue_ended
	animacion.play("final")
	await get_tree().create_timer(3).timeout
	%Player.return_control(self)
	
