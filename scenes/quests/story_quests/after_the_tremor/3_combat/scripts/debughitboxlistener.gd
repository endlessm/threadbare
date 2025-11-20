# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

# Script mínimo: imprime info cuando algo entra al Hitbox.
# Conectar las señales desde el editor (ver pasos abajo).

func _on_Hitbox_body_entered(body: Node) -> void:
	if not body:
		return
	var cls: String = body.get_class()
	var can_hit: Variant = body.get("can_hit_enemy")
	print("[DEBUG] body_entered -> node:", body.name, " class:", cls, " can_hit_enemy:", can_hit)

func _on_Hitbox_area_entered(area: Node) -> void:
	if not area:
		return
	var cls: String = area.get_class()
	var can_hit: Variant = area.get("can_hit_enemy")
	print("[DEBUG] area_entered -> node:", area.name, " class:", cls, " can_hit_enemy:", can_hit)


func _on_hit_box_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hit_box_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
