extends Node2D
@onready var enemigos = get_tree().get_nodes_in_group("enemigos")

func _ready() -> void:
	for e in enemigos:
		e.player_detected.connect(%Player.defeat);
