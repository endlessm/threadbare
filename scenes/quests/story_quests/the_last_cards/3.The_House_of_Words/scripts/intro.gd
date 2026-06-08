extends Node2D

func _ready():
	$BtnContinuar.pressed.connect(_on_continuar)

func _on_continuar():
	get_tree().change_scene_to_file("res://scenes/Exterior.tscn")
