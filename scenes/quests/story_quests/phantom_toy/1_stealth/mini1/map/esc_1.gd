# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

	
@onready var objeto1 = $Objeto1
@onready var objeto2 = $Objeto2
@onready var objeto3 = $Objeto3
var objetos_recogidos := 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()

	var puntos = []

	for p in $SpawnPoints.get_children():
		puntos.append(p.global_position)

	puntos.shuffle()

	objeto1.global_position = puntos[0]
	objeto2.global_position = puntos[1]
	objeto3.global_position = puntos[2]
	
	
func recoger_objeto():
	objetos_recogidos += 1

	print("Recogidos: ", objetos_recogidos)

	if objetos_recogidos >= 3:
		print("GANASTE")

		# CAMBIAR POR TU SIGUIENTE ESCENA
		SceneSwitcher.change_to_file_with_transition(
			"res://scenes/quests/story_quests/phantom_toy/3.5_phantom_toy_corruption_defense/phantom_toy_corruption_defense.tscn",
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_cinematic_cinematic_finished() -> void:
	$Enemy.visible = true
	$Enemy.active = true
