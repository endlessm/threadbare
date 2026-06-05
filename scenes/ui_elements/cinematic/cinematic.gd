# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D
## Shows a dialogue, then transitions to another scene.
##
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest.
## It can also be used as an easy way to display dialogue at the beginning of a level.

## Emitted when the cinematic has finished. Use it if not passing [member next_scene]
## when you need to do something else after the cinematic.
signal cinematic_finished

## Dialogue for cinematic scene.
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Optional animation player, to be used from [member dialogue] (if needed).
@export var animation_player: AnimationPlayer

## Optional scene to switch to once [member dialogue] is complete.
@export_file("*.tscn") var next_scene: String

## Optional path inside [member next_scene] where the player should appear.
## If blank, player appears at default position in the scene. If in doubt,
## leave this blank.
@export var spawn_point_path: String

## Wether to automatically start the cinematic.
@export var autostart: bool = true

## La cámara del jugador que tomará el control al finalizar el diálogo.
@export var player_camera: Camera2D 

@export var actor_cinematica: Node2D
@export var jugador_real: Node2D

func _ready() -> void:
	if jugador_real:
		jugador_real.hide()
		jugador_real.process_mode = Node.PROCESS_MODE_DISABLED
	if autostart:
		start()


func start() -> void:
	if not GameState.intro_dialogue_shown:
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		cinematic_finished.emit()
		GameState.intro_dialogue_shown = true
		
		if actor_cinematica:
			actor_cinematica.queue_free()
			
		
		if jugador_real:
			if actor_cinematica:
				jugador_real.global_position = actor_cinematica.global_position
				
			jugador_real.show()
			jugador_real.process_mode = Node.PROCESS_MODE_INHERIT # Descongela al jugador
			
			var camara = jugador_real.get_node_or_null("Camera2D")
			if camara:
				camara.make_current()

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
