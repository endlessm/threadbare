# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

@export var player_instantly_loses_on_sight: bool = false:
	set = set_player_instantly_loses_on_sight
@export_range(0.5, 3.0, 0.1, "or_greater", "or_less") var zoom: float = 1.0:
	set = set_zoom


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_player_instantly_loses_on_sight(player_instantly_loses_on_sight)
	set_zoom(zoom)


func set_player_instantly_loses_on_sight(new_value: bool) -> void:
	player_instantly_loses_on_sight = new_value
	if not is_node_ready():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_instantly_detected_on_sight = player_instantly_loses_on_sight


func set_zoom(new_value: float) -> void:
	zoom = new_value
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	camera.zoom = Vector2.ONE * zoom
