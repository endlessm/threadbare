# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node


func _ready() -> void:
	var powerup := get_parent()
	if not GameState.player.has_ability(powerup.ability):
		_set_shown(powerup, false)
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_dialogue_ended(_resource: Resource) -> void:
	var powerup := get_parent()
	if GameState.player.has_ability(powerup.ability):
		return
	_set_shown(powerup, true)


func _set_shown(powerup: Node, shown: bool) -> void:
	powerup.visible = shown
	powerup.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
