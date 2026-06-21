extends Area2D
class_name ZonaPresion

# Señales para avisarle al controlador del puzzle
signal caja_colocada
signal caja_retirada

var esta_activada: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	# SOLUCIÓN DEL ERROR: En lugar de usar 'is CajaEmpujable', comprobamos si el nodo
	# se llama "Caja" o si tiene la función 'empujar' que creamos en su script.
	if (body.has_method("empujar") or "Caja" in body.name) and not esta_activada:
		esta_activada = true
		modulate = Color(0.5, 1.0, 0.5) # Cambia a verde visualmente para dar feedback al jugador
		caja_colocada.emit()

func _on_body_exited(body: Node) -> void:
	if (body.has_method("empujar") or "Caja" in body.name) and esta_activada:
		esta_activada = false
		modulate = Color(1.0, 1.0, 1.0) # Vuelve a su color original si sacan la caja
		caja_retirada.emit()
