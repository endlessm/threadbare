extends Puerta
class_name Puerta_ganzua

var escena_ya_completada: bool = false

func _ready():
	next_scene_path = "res://scenes/quests/story_quests/template_laberinto/3_laberinto_sequence_puzzle/template_sequence_laberinto_puzzle.tscn"
	super()  # Llama al _ready() de Puerta

	# Detectar si esta puerta ya fue forzada previamente (es decir, ya volviste del minijuego)
	if GameStateLaberinto.puerta_ganzua_forzada:
		escena_ya_completada = true
		print("🟢 La puerta ganzúa ya fue forzada. Desactivando interacción.")
		animated_sprite_2d.play("Abierto")
		$CollisionShape2D.disabled = true
		ui_container.visible = false
		set_process(false)  # Opcional: desactiva procesamiento si ya no hace falta

func check_door_status():
	is_unlocked = true
	show_unlocked_ui()

func show_unlocked_ui():
	if not escena_ya_completada:
		ui_container.visible = true
		interact_label.text = "Presiona E para forzar la puerta"

func interact():
	if escena_ya_completada:
		return  # Si ya fue forzada, no hacer nada

	if player_in_range:
		animated_sprite_2d.play("Abierto")

		# Guardar el estado antes de cambiar de escena
		if current_player:
			GameStateLaberinto.player_position = current_player.global_position
			GameStateLaberinto.llaves = current_player.keys_collected
			GameStateLaberinto.abiertos = current_player.get_cofres_abiertos()
			GameStateLaberinto.puerta_ganzua_forzada = true  # Marcar que ya fue usada

			print("✅ Estado guardado antes de cambiar de escena:")
			print("- Posición:", GameStateLaberinto.player_position)
			print("- Llaves:", GameStateLaberinto.llaves)
			print("- Cofres abiertos:", GameStateLaberinto.abiertos)
			print("- Puerta ganzúa forzada: true")

		change_scene()
