extends Node2D
@onready var marker_2d: Marker2D = $sprite_de_arma_1/Marker2D
var bala = preload("res://scenes/quests/story_quests/spacerage/pruebas/disparo_1.tscn")
@export var speed = 400

func get_input():
	look_at(get_global_mouse_position())

func _physics_process(delta):
	get_input()
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var bala_nueva = bala.instantiate()
		bala_nueva.global_position = marker_2d.global_position
		bala_nueva.direccion = marker_2d.global_position.direction_to(get_global_mouse_position())
		get_tree().current_scene.add_child(bala_nueva)
		print("Disparo desde", marker_2d.global_position)
		
