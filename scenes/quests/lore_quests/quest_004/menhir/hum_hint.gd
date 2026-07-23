# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var required_ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_C

@onready var _hint: Control = $HumInputHint


func _ready() -> void:
	var controls := _get_hud_controls()
	if controls == null:
		_hint.hide()
		return

	remove_child(_hint)
	controls.add_child(_hint)

	var aim := controls.get_node_or_null(^"AimInputHint")
	if aim:
		controls.move_child(_hint, aim.get_index())

	GameState.player.abilities_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if is_instance_valid(_hint):
		_hint.queue_free()


func _get_hud_controls() -> Node:
	var hud: Node = get_node_or_null(^"/root/InputHud")
	if hud == null:
		return null
	return hud.get("normal_controls") as Node


func _refresh() -> void:
	if is_instance_valid(_hint):
		_hint.visible = GameState.player.has_ability(required_ability)
