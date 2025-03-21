@tool
extends Node
@onready var enemy_guards: Node2D = %EnemyGuards
@onready var camera_2d: Camera2D = $"../OnTheGround/Player/Camera2D"

@export_range(0.5, 3.0, 0.1) var detection_area_scale: float = 1.0 :
	set(new_value):
		detection_area_scale = new_value
		if enemy_guards:
			for child in enemy_guards.get_children():
				var guard = child as Guard
				if guard:
					guard.detection_area_scale = detection_area_scale
@export var player_instantly_loses_on_sight: bool = false :
	set(new_value):
		player_instantly_loses_on_sight = new_value
		if enemy_guards:
			for child in enemy_guards.get_children():
				var guard = child as Guard
				if guard:
					guard.player_instantly_loses_on_sight = player_instantly_loses_on_sight
@export_range(0.5, 3.0, 0.1) var zoom: float = 1.0 :
	set(new_value):
		zoom = new_value
		if camera_2d:
			camera_2d.zoom = Vector2.ONE * zoom
