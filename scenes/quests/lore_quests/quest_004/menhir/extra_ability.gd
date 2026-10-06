# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var extra_ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_B_MODIFIER_1


func _ready() -> void:
	var powerup := get_parent()
	if powerup and powerup.has_signal(&"collected"):
		powerup.collected.connect(_on_parent_collected)


func _on_parent_collected() -> void:
	GameState.player.set_ability(extra_ability, true)
