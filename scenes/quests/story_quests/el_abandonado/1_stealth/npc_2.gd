extends Node2D

var puede_hablar = false

@export var dialogue: DialogueResource


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		puede_hablar = true
		$Label.text = "Presiona ESPACIO"


func _on_area_2d_body_exited(body):
	if body.name == "Player":
		puede_hablar = false
		$Label.text = ""


func _process(delta):
	if puede_hablar and Input.is_action_just_pressed("ui_accept"):
		DialogueManager.show_dialogue_balloon(
			dialogue,
			"",
			[self]
		)
