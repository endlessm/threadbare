extends Puerta
class_name Puerta_ganzua

var escena_ya_completada: bool = false
@export var puerta_id: String = ""

func _ready():
	next_scene_path = "res://scenes/quests/story_quests/template_laberinto/3_laberinto_sequence_puzzle/template_sequence_laberinto_puzzle.tscn"
	super()

	if GameStateLaberinto.puertas_ganzua_forzadas.get(puerta_id, false):
		escena_ya_completada = true
		print("🟢 La puerta %s ya fue forzada. Desactivando interacción." % puerta_id)
		animated_sprite_2d.play("Abierto")
		$CollisionShape2D.disabled = true
		ui_container.visible = false
		set_process(false)

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
			GameStateLaberinto.puertas_ganzua_forzadas[puerta_id] = true


		change_scene()
