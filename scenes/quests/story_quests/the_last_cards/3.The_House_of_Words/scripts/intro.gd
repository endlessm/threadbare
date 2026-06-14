extends Node2D

func _ready():
	$BtnContinuar.pressed.connect(_on_continuar)

func _on_continuar():
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room1.tscn")
