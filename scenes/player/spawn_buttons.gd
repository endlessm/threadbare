extends Timer

var player: Player

const PLAYER_BULLET = preload("res://scenes/player_bullet.tscn")

func _ready() -> void:
	if owner is Player:
		player = owner

func _on_timeout() -> void:
	var player_bullet = PLAYER_BULLET.instantiate()
	player_bullet.global_position = owner.global_position
	player_bullet.initial_impulse = player.last_nonzero_axis * 1000
	owner.get_parent().add_child(player_bullet)
