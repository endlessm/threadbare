# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var dead_end_camera: PhantomCamera2D = %DeadEndCamera
@onready var bridge_camera: PhantomCamera2D = %BridgeCamera


func _on_dead_end_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		dead_end_camera.priority = 20


func _on_dead_end_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		dead_end_camera.priority = 0


func _on_bridge_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		bridge_camera.priority = 20


func _on_bridge_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		bridge_camera.priority = 0
