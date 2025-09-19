extends AnimatedSprite2D

func _input(event):
	if event.is_action_pressed("ui_select"):
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/shjourney/2_shjourney_intro/template_intro.tscn")
