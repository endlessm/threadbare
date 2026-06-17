# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D
 
signal cinematic_finished

@onready var fade_rect = $ColorRect
@onready var anim = $AnimationPlayer
 
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")
@export var dialogue_02: DialogueResource = preload("res://scenes/quests/story_quests/perdidos_en_el_desie/4_outro/outro_components/el_ultimo_adios.dialogue")


## Wether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	if autostart:
		start()


func start() -> void:
	# Animación de cierre
	fade_rect.self_modulate.a = 0
	#Para la animación del personaje
	var character:Node2D = get_node("../OnTheGround/Personaje")
	# Pantalla en blanco
	await mostrar_dialogo(dialogue,true)
	await character.mover_a_recuerdos()
	await mostrar_dialogo(dialogue_02,false)
	await character.mover_a_salida()
	GameState.intro_dialogue_shown = true
	
	# Función de cierre 
	anim.play("fade_out")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
	
func mostrar_dialogo(dialogo: DialogueResource,mover:bool)-> void:
	@warning_ignore("untyped_declaration")
	var diague = DialogueManager.show_dialogue_balloon(dialogo, "", [self])
	var diague_ui:Control = diague.get_node("Balloon")
	await get_tree().process_frame
	var size_viewport:Vector2 = get_viewport().size
	if(mover):
		diague_ui.position = Vector2(
			size_viewport.x - 500, 20
		)
	await DialogueManager.dialogue_ended
	cinematic_finished.emit()
	
	# Función de cierre
 
		

 

	
