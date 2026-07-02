# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends "res://scenes/game_elements/props/collectible_item/components/collectible_item.gd"

func _on_alma_del_padre_boss_defeated() -> void:
	reveal()
