extends Node2D

@onready var mira_disparo = $mira_disparo
var bala_scene = preload("res://scenes/quests/story_quests/spacerage/pruebas/bala.tscn") 

func _process(delta):
	look_at(get_global_mouse_position())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var bala = bala_scene.instantiate()
		bala.global_position = mira_disparo.global_position
		bala.direccion = (get_global_mouse_position() - bala.global_position).normalized()
		bala.daño = 3 
		get_tree().current_scene.add_child(bala)
