extends Node2D

func _ready():
	$BtnReintentar.pressed.connect(_on_reintentar)
	$BtnMenu.pressed.connect(_on_menu)

func _on_reintentar():
	get_tree().change_scene_to_file("res://scenes/Room1.tscn")

func _on_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
