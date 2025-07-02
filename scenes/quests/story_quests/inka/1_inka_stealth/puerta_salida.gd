extends Area2D

var player_inside = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		print("Jugador entró en la puerta")  # 👈 AÑADE ESTO


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _input(event):
	if player_inside and event.is_action_pressed("ui_accept"):
		print("Presionaste Enter dentro del área")  # 👈 para depurar
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/inka/3_inka_sequence_puzzle/inka_sequence_puzzle.tscn")
