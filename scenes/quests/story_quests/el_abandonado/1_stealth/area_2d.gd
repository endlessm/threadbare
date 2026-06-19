extends Area2D

var activado := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if activado:
		return

	if body.name != "Player":
		return

	activado = true

	for nodo in get_tree().get_nodes_in_group("hadas"):

		if nodo.has_method("mostrar_frase"):
			nodo.mostrar_frase()
