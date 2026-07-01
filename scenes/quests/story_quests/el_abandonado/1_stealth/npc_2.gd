extends Node2D

var puede_hablar = false
var dialogo_abierto = false

@export var dialogue: DialogueResource

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		puede_hablar = true
		$Label.text = "Presiona ESPACIO"

func _on_area_2d_body_exited(body):
	if body.name == "Player":
		puede_hablar = false
		$Label.text = ""

func _process(_delta):

	if puede_hablar \
	and not dialogo_abierto \
	and Input.is_action_just_pressed("ui_accept"):

		iniciar_dialogo()

func iniciar_dialogo() -> void:

	dialogo_abierto = true

	var balloon = DialogueManager.show_dialogue_balloon(
		dialogue,
		"",
		[self]
	)

	await balloon.tree_exited

	while Input.is_action_pressed("ui_accept"):
		await get_tree().process_frame

	dialogo_abierto = false
