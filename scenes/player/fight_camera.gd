extends Node2D

var player: Player

@onready var player_fighting: PlayerFighting = %PlayerFighting
@onready var camera_2d: Camera2D = %Camera2D

var target_position: Vector2

func _ready() -> void:
	if owner is Player:
		player = owner

func _process(_delta: float) -> void:
	if not player:
		return
	if not player_fighting.is_fighting:
		target_position = Vector2.ZERO
	else:
		target_position = player.last_nonzero_axis * Vector2(16, 9) * 15
	camera_2d.position = camera_2d.position.lerp(target_position, 0.03)
