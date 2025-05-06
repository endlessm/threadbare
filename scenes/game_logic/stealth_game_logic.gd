# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

@export var player_instantly_loses_on_sight: bool = false:
	set = _set_player_instantly_loses_on_sight
@export_range(0.5, 3.0, 0.1, "or_greater", "or_less") var zoom: float = 1.0:
	set = _set_zoom


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_set_player_instantly_loses_on_sight(player_instantly_loses_on_sight)
	_set_zoom(zoom)
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)


func _on_player_detected(player: Node2D) -> void:
	player.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	await get_tree().create_timer(2.0).timeout
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)


func _set_player_instantly_loses_on_sight(new_value: bool) -> void:
	player_instantly_loses_on_sight = new_value
	if not is_node_ready():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_instantly_detected_on_sight = player_instantly_loses_on_sight


func _set_zoom(new_value: float) -> void:
	zoom = new_value
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	camera.zoom = Vector2.ONE * zoom
