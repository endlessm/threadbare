# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Area2D

const HINT_FADE_SPEED = 5.0

@export var hint_node: CanvasItem:
	set(new_value):
		hint_node = new_value
		update_configuration_warnings()
@export_category("Condition")
@export var condition_node: Node
@export var condition_method: StringName


func _get_configuration_warnings() -> PackedStringArray:
	if not hint_node:
		return ["hint_node must be set"]
	return []


func _ready():
	if Engine.is_editor_hint():
		return

	hint_node.modulate.a = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var target_hint_node_alpha: float = 1.0 if has_overlapping_bodies() else 0.0
	hint_node.modulate.a = move_toward(
		hint_node.modulate.a, target_hint_node_alpha, delta * HINT_FADE_SPEED
	)
