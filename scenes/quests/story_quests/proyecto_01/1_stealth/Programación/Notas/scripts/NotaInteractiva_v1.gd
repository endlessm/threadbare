extends Area2D

@export var imagen_nota: Texture2D

var panel_nota: Node = null
var jugador_en_area := false
var nota_visible := false
var e_was_down := false # para detectar “just pressed” sin InputMap

func _ready():
	await get_tree().process_frame
	# 1) Localiza el panel
	panel_nota = get_tree().current_scene.get_node("NotaPanel_v1")
	if panel_nota == null:
		push_error("[NOTA] No se encontró el nodo NotaPanel_v1 en la escena actual.")
	else:
		panel_nota.visible = false
		print("[NOTA] Panel encontrado y oculto al iniciar.")

	# 2) Asegúrate de que el Area2D esté monitoreando
	monitoring = true
	monitorable = true
	print("[NOTA] Area2D monitoring:", monitoring, "  monitorable:", monitorable)

func _process(_delta):
	var e_down := Input.is_key_pressed(KEY_E) # tecla física E (sin InputMap)

	# Traza para ver el estado cuando estás dentro del área
	if jugador_en_area and e_down and not e_was_down:
		print("[NOTA] E detectada. jugador_en_area=", jugador_en_area, " visible=", nota_visible)

		if panel_nota == null:
			push_error("[NOTA] No hay panel_nota. Aborta.")
			e_was_down = e_down
			return

		if not nota_visible:
			if imagen_nota == null:
				push_warning("[NOTA] imagen_nota no asignada; se mostrará vacío.")
			panel_nota.mostrar(imagen_nota)
			nota_visible = true
			print("[NOTA] MOSTRAR nota")
		else:
			panel_nota.ocultar()
			nota_visible = false
			print("[NOTA] OCULTAR nota")

	e_was_down = e_down

func _on_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_area = true
		print("[NOTA] Jugador entró al área. Presiona E para leer.")

func _on_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_area = false
		print("[NOTA] Jugador salió del área.")
		if nota_visible and panel_nota:
			panel_nota.ocultar()
			nota_visible = false
			print("[NOTA] Cerrar nota por salir del área.")
