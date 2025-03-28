# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
extends Node


func change_scene_to(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if get_tree().change_scene_to_file(scene_path) == OK and spawn_point != ^"":
		GameState.current_spawn_point = spawn_point
