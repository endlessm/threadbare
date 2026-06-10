extends Player
class_name CorruptionPlayer

func _toggle_abilities() -> void:
	_toggle_player_behavior(player_repel, false)
	_toggle_player_behavior(player_hook, false)
