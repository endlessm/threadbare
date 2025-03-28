# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SpawnPoint
extends Marker2D


func _init() -> void:
	add_to_group("spawn_point", true)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if GameState.current_spawn_point == owner.get_path_to(self):
		move_player_to_self_position()


func move_player_to_self_position() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")

	if is_instance_valid(player):
		player.teleport_to(self.global_position)
