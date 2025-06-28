extends Control
func _ready():
	# Asegurarse que el puzzle esté oculto al inicio
	$PuzzleContainer.visible = false
	# Habilitar arrastre
	$PuzzleContainer/Bloque_sudo.set_drag_forwarding(self)
	$PuzzleContainer/Bloque_access.set_drag_forwarding(self)
	$PuzzleContainer/Bloque_root.set_drag_forwarding(self)

func _on_CarpetaBtn1_pressed():
	$MostrarTexto.bbcode_text = "[b]private_logs:[/b]\n7 de marzo...\nLa isla vuelve a actuar rara...\nNo soy el único que escucha voces en la cabaña..."

func _on_CarpetaBtn2_pressed():
	$MostrarTexto.bbcode_text = "[b]obs.txt:[/b]\nObservador conectado...\nEstás dentro, Elena.\n¿Recuerdas la contraseña?"

func _on_EntradaComando_text_submitted(text):
	var comando = text.strip_edges().to_lower()
	if comando == "open revelation.txt":
		$MostrarTexto.bbcode_text = "[color=red]Accediendo...[/color]\nArchivo desbloqueado."
		$PuzzleContainer.visible = true
	else:
		$MostrarTexto.bbcode_text = "[i]Comando no reconocido...[/i]"
# Variables para almacenar qué bloque cayó en cada slot
var orden_slots = ["", "", ""]


func get_drag_data(position):
	var control = get_viewport().gui_get_drag_data_control()
	if control:
		var preview = control.duplicate()
		set_drag_preview(preview)
		return control.name
	return null

func can_drop_data(position, data):
	return true

func drop_data(position, data):
	var slot_encontrado = null
	if $PuzzleContainer/Slot1.get_global_rect().has_point(position):
		slot_encontrado = 0
	elif $PuzzleContainer/Slot2.get_global_rect().has_point(position):
		slot_encontrado = 1
	elif $PuzzleContainer/Slot3.get_global_rect().has_point(position):
		slot_encontrado = 2

	if slot_encontrado != null:
		orden_slots[slot_encontrado] = data
		$PuzzleContainer/ResultadoLabel.text = "Bloque colocado en Slot" + str(slot_encontrado + 1)

func _on_BotonVerificar_pressed():
	if orden_slots == ["Bloque_sudo", "Bloque_access", "Bloque_root"]:
		$PuzzleContainer/ResultadoLabel.text = "¡Código correcto! Acceso concedido."
	else:
		$PuzzleContainer/ResultadoLabel.text = "Código incorrecto. Intenta de nuevo."
