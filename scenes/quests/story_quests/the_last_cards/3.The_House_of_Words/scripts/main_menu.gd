extends Node2D

func _ready():
	$BtnJugar.pressed.connect(_on_btn_jugar_pressed)
	$BtnCreditos.pressed.connect(_on_btn_creditos_pressed)
	$BtnSalir.pressed.connect(_on_btn_salir_pressed)

func _on_btn_jugar_pressed():
	get_tree().change_scene_to_file("res://scenes/Intro.tscn")

func _on_btn_creditos_pressed():
	pass  # después

func _on_btn_salir_pressed():
	get_tree().quit()
