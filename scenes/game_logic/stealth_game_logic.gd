# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

@export var obstaculo:Node2D
@export var camara:Sprite2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)


func _on_player_detected(player: Node2D) -> void:
	if player.has_method("defeat"):
		player.defeat()
	else:
		push_warning("Detected node does not have defeat() method", player)

var jugador_en_rango = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	jugador_en_rango = true
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("throw"):
		if jugador_en_rango: 
			if obstaculo: 
				obstaculo.queue_free()
				camara.visible=true
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	jugador_en_rango = false
