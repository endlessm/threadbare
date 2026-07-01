extends Player
class_name CorruptionPlayer

var previous_positions := []


func _physics_process(_delta):

	previous_positions.push_front(global_position)

	if previous_positions.size() > 30:
		previous_positions.pop_back()


func _toggle_abilities() -> void:
	_toggle_player_behavior(player_repel, false)
	_toggle_player_behavior(player_hook, false)
