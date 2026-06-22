# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

var puede_disparar: bool = false
var balas_restantes: int = 3
var ultima_direccion: Vector2 = Vector2.RIGHT

const ESCENA_PROYECTIL := preload("res://scenes/quests/story_quests/perdidos_en_el_desie/2_combat/proyectil.tscn")


func _physics_process(_delta: float) -> void:
	var player := _get_player()
	if not player:
		return
	var direccion := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if direccion.length() > 0.0:
		ultima_direccion = direccion.normalized()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		intentar_disparar()


func activar_disparo() -> void:
	puede_disparar = true
	var player := _get_player()
	if player:
		player.mode = Player.Mode.USER_CONTROLLED


func intentar_disparar() -> void:
	var player := _get_player()
	if not puede_disparar or balas_restantes <= 0 or player == null:
		return
	if player.mode != Player.Mode.USER_CONTROLLED:
		return

	balas_restantes -= 1
	var proyectil: Node2D = ESCENA_PROYECTIL.instantiate()
	get_parent().add_child(proyectil)
	proyectil.iniciar(player.global_position, ultima_direccion)


func _get_player() -> Player:
	return get_parent().find_child("Player", true, false) as Player
