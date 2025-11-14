extends Node

var count := 0

func add_point():
	count += 1
	print("Contador = ", count)

	if count >= 4:
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/shadown_studios/2_combat/shadown_studios_combat.tscn")
