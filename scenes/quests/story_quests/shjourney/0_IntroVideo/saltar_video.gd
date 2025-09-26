extends VideoStreamPlayer

func _input(event):
	if event.is_action_pressed("ui_select"):
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/shjourney/1_IntroAnimacion/SleepingBros.tscn")
