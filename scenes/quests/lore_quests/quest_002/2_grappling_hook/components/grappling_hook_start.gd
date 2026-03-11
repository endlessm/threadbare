# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _ready() -> void:
	GameState.set_ability(Enums.PlayerAbilities.ABILITY_B, true)
