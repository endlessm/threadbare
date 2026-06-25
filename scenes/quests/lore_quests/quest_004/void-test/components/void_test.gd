# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var zoom_tween: Tween

@onready var player: Player = %Player
@onready var void_chasing: CharacterBody2D = %VoidChasing


func _ready() -> void:
	GameState.abilities_changed.connect(_on_abilities_changed)
	_assign_void_layer()


func _assign_void_layer() -> void:
	var void_node := find_child("Void", true, false)
	if not void_node:
		return
	for enemy in find_children("", "CharacterBody2D", true, false):
		if "void_layer" in enemy and enemy.void_layer == null:
			enemy.void_layer = void_node


func _on_abilities_changed() -> void:
	var has_longer_thread := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1)
	var camera_zoom := Vector2(0.5, 0.5) if has_longer_thread else Vector2(1.0, 1.0)
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera.zoom != camera_zoom:
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", camera_zoom, 1.0)


func _on_longer_thread_powerup_collected() -> void:
	void_chasing.start(player)
