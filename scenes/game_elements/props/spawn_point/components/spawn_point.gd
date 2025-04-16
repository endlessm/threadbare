# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SpawnPoint
extends Marker2D

@export var look_at_side_on_spawn: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED


func _init() -> void:
	add_to_group("spawn_point", true)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if GameState.current_spawn_point == get_tree().current_scene.get_path_to(self):
		move_player_to_self_position()


func move_player_to_self_position(smooth_camera: bool = false) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")

	if is_instance_valid(player):
		player.teleport_to(self.global_position, smooth_camera, look_at_side_on_spawn)
