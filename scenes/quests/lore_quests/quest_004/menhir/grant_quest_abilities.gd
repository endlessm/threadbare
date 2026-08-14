# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var grant_sword: bool = true
@export var grant_hook: bool = true
@export var grant_longer_hook: bool = true
@export var grant_tarareo: bool = true


func _ready() -> void:
	if grant_sword:
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_A, true)
	if grant_hook:
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_B, true)
	if grant_longer_hook:
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1, true)
	if grant_tarareo:
		GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_C, true)
