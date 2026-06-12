# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D
 
signal cinematic_finished
 
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Wether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	if autostart:
		start()


func start() -> void:
	var diague = DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	var diague_ui:Control = diague.get_node("Balloon")
	await get_tree().process_frame
	await get_tree().process_frame
  
	var size_viewport:Vector2 = get_viewport().size
 
	diague_ui.position = Vector2(
		size_viewport.x - 500, 20
	)
	
	await DialogueManager.dialogue_ended
	cinematic_finished.emit()
	GameState.intro_dialogue_shown = true

	var character:AnimatedSprite2D = get_node("../OnTheGround/Character")
	await character.mover_a_salida()
	
	get_tree().quit()
	

 

	
