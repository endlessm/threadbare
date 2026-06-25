extends Area2D

@export var siguiente_escena: String = "res://scenes/quests/story_quests/the_last_cards/1_stealth/the_hospital_2piso.tscn"

func _ready() -> void:
	# Conecta la señal automáticamente si el script está en el Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		call_deferred("_cambiar_escena")

func _cambiar_escena() -> void:
	get_tree().change_scene_to_file(siguiente_escena)
