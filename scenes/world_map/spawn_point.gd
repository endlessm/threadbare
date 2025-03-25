@tool
class_name SpawnPoint
extends Marker2D


func _init() -> void:
	add_to_group("spawn_point", true)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if GameState.current_spawn_point == owner.get_path_to(self):
		move_player_to_self_position()


func move_player_to_self_position() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")

	if is_instance_valid(player):
		player.teleport_to(self.global_position)
