# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	# TODO: What abilities are available in "hub"?
	if player:
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_A, true)
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_B, true)
