@tool
extends Node

@export var player_instantly_loses_on_sight: bool = false:
	set = set_player_instantly_loses_on_sight
@export_range(0.5, 3.0, 0.1, "or_greater", "or_less") var zoom: float = 1.0:
	set = set_zoom

@onready var enemy_guards: Node2D = %EnemyGuards
@onready var camera_2d: Camera2D = %Camera2D


func set_player_instantly_loses_on_sight(new_value: bool) -> void:
	player_instantly_loses_on_sight = new_value
	if not enemy_guards:
		return
	for child: Node in enemy_guards.get_children():
		var guard := child as Guard
		if not guard:
			continue
		guard.player_instantly_detected_on_sight = player_instantly_loses_on_sight


func set_zoom(new_value: float) -> void:
	zoom = new_value
	if camera_2d:
		camera_2d.zoom = Vector2.ONE * zoom
