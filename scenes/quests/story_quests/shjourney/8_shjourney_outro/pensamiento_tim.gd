extends Area2D

@export var texto_tim: String = "¡Malditos árboles! No pienso detenerme ahora."
@export var tiempo_visible: float = 3.0

var activado := false

func _on_body_entered(body):
	if activado:
		return

	if body.is_in_group("player"):
		activado = true
		mostrar_pensamiento()

func mostrar_pensamiento():
	var label = get_tree().get_root().get_node("HUD/DialogueLabel")
	if label:
		var line = DialogueLine.new({"text": texto_tim})
		label.dialogue_line = line
		label.show()
		label.type_out()
