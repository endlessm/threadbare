class_name ButtonsSpawner
extends Node2D

const PLAYER_BULLET = preload("res://scenes/player_bullet.tscn")

var player: Player
var spawn_direction: Vector2

@onready var player_fighting: PlayerFighting = %PlayerFighting


func _ready() -> void:
	if owner is Player:
		player = owner

func _process(_delta: float) -> void:
	if not player_fighting.is_fighting:
		spawn_direction = Vector2.ZERO

func spawn() -> void:
	if not player:
		return
	if not spawn_direction or spawn_direction.angle_to(player.last_nonzero_axis) >= PI:
		spawn_direction = player.last_nonzero_axis
	spawn_direction = spawn_direction.lerp(player.last_nonzero_axis, 0.5)
	var player_bullet = PLAYER_BULLET.instantiate()
	player_bullet.global_position = global_position
	player_bullet.initial_impulse = spawn_direction * 1000
	owner.get_parent().add_child(player_bullet)
