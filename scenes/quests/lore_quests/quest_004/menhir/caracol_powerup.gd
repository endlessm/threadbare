# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var icon_scale: float = 0.35
@export var bob_amplitude: float = 6.0
@export var bob_period: float = 1.2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var powerup := get_parent()
	var sprite := powerup.get_node_or_null("Sprite") as Node2D

	if sprite:
		sprite.scale = Vector2(icon_scale, icon_scale)

	if not GameState.has_ability(powerup.ability):
		_set_shown(powerup, false)
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	if sprite:
		_start_bob(sprite)


func _on_dialogue_ended(_resource: Resource) -> void:
	var powerup := get_parent()
	if GameState.has_ability(powerup.ability):
		return
	_set_shown(powerup, true)


func _set_shown(powerup: Node, shown: bool) -> void:
	powerup.visible = shown
	powerup.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED


func _start_bob(sprite: Node2D) -> void:
	var base_y := sprite.position.y
	var t := create_tween().set_loops()
	t.tween_property(sprite, "position:y", base_y - bob_amplitude, bob_period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(sprite, "position:y", base_y, bob_period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
