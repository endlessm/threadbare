extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Puzzle8.tscn")
