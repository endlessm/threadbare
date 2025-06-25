# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## Shows a dialogue, then transitions to another scene.
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest
class_name cinematic_intro
extends Node2D

## Dialogue for cinematic scene
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Animation player, to be used from [member dialogue] (if needed)
@export var animation_player: AnimationPlayer

## Scene to switch to once [member dialogue] is complete
@export_file("*.tscn") var next_scene: String

## Optional path inside [member next_scene] where the player should appear.
## If blank, player appears at default position in the scene. If in doubt,
## leave this blank.
@export var spawn_point_path: String


func _ready() -> void:
	
	# Activar la cámara de la cinemática desde el comienzo
	var cinematic_camera := $CinematicCamera
	if cinematic_camera:
		cinematic_camera.make_current()
	
	$AnimationPlayer.play("CinematicPan")
	
	DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended
	
	# Hacer el fade antes de activar el jugador
	get_parent().get_node("Fade").visible = true
	$FadeAnimator.play("fade_in_out")
	
	# Ocultar el personaje de la cinemática
	var fake_player: AnimatedSprite2D = get_parent().get_node("OnTheGround/Character")
	if fake_player:
		fake_player.visible = false
		fake_player.process_mode = Node.PROCESS_MODE_DISABLED
		

	# Activar al jugador real
	var real_player: Player = get_parent().get_node("Player") as Player
	if real_player:
		real_player.visible = true
		real_player.process_mode = Node.PROCESS_MODE_INHERIT
		real_player.mode = Player.Mode.COZY

	# 🔁 CAMBIO DE CÁMARAS
	# Desactiva la cámara de la cinemática
	var real_camera:Camera2D = get_parent().get_node_or_null("Player/Camera2D") as Camera2D
	if real_camera:
		real_camera.make_current()  # Activa la cámara real
		
	await $FadeAnimator.animation_finished

	if next_scene:
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				spawn_point_path,
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)
