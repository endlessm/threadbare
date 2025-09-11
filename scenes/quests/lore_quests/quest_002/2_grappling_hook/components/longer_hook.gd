# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Object


static func grant_longer_hook(player: Player) -> void:
	player.get_node("%PlayerHook").string_throw_length = 400.0
	player.get_node("%PlayerHook").string_max_length = 450.0
