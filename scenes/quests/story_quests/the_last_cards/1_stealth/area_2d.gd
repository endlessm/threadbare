extends Area2D

@export var siguiente_escena: String = "res://scenes/quests/story_quests/the_last_cards/1_stealth/the_hospital_2piso.tscn"

func _ready():
	# Conecta la señal automáticamente si el script está en el Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(siguiente_escena)
