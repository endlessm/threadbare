# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		scale = Vector2(randf_range(0.8, 1.2), randf_range(0.8, 1.2))


func _ready() -> void:
	$AnimatedSprite2D.play("default")
