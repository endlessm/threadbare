# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@export var player_path: NodePath
@export var essence_progress_bar_path: NodePath
@export var health_container_path: NodePath
@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

@onready var _player: Node = get_node_or_null(player_path)
@onready var _essence_progress_bar: TextureProgressBar = get_node(
	essence_progress_bar_path
) as TextureProgressBar
@onready var _health_container: HBoxContainer = get_node(health_container_path) as HBoxContainer


func _ready() -> void:
	if _player == null:
		push_warning("Echo Abyss HUD needs a Player node assigned.")
		return

	var health_changed_callable := Callable(self, "_on_health_changed")
	var essence_changed_callable := Callable(self, "_on_essence_changed")
	if not _player.is_connected(&"health_changed", health_changed_callable):
		_player.connect(&"health_changed", health_changed_callable)
	if not _player.is_connected(&"essence_changed", essence_changed_callable):
		_player.connect(&"essence_changed", essence_changed_callable)

	_on_health_changed(_player.get_current_health(), _player.get_max_health())
	_on_essence_changed(_player.get_current_essence(), _player.get_max_essence())


func _on_health_changed(current_health: int, max_health: int) -> void:
	var hearts := _heart_nodes()
	for index in range(hearts.size()):
		var heart := hearts[index]
		heart.visible = index < max_health
		heart.texture = full_heart_texture if index < current_health else empty_heart_texture


func _on_essence_changed(current_essence: int, max_essence: int) -> void:
	_essence_progress_bar.min_value = 0
	_essence_progress_bar.max_value = max_essence
	_essence_progress_bar.value = current_essence


func _heart_nodes() -> Array[TextureRect]:
	var hearts: Array[TextureRect] = []
	for child in _health_container.get_children():
		var heart := child as TextureRect
		if heart != null:
			hearts.append(heart)
	return hearts
