# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const LongerHook = preload(
	"res://scenes/quests/lore_quests/quest_002/2_grappling_hook/components/longer_hook.gd"
)


func _ready() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	LongerHook.grant_longer_hook(player)
