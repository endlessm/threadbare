# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
signal outro_finished

@onready var camera: Camera2D = $"../Camera2D"
@onready var lino_animation: AnimationPlayer = $"../OnTheGround/AnimationPlayer"
@onready var tilemap_walls: TileMapLayer = $"../CabanaParedes"
@onready var tilemap_furnitures: TileMapLayer = $"../Furnitures"

# --- CORE FIX: TARGET THE SCREENOVERLAY AND TEXT NODES ---
@onready var screen_overlay: CanvasLayer = $"../ScreenOverlay"
@onready var fade_rect: ColorRect = $"../ScreenOverlay/ColorRect" 
@onready var texto_final: RichTextLabel = $"../ScreenOverlay/ColorRect/RichTextLabel" # <-- Referencia al nodo de texto

const DIALOGO_OUTRO = preload("res://scenes/quests/story_quests/el_hilo_que_no_teji/4_outro/outro_components/el_hilo_que_no_teji_outro.dialogue")

func _ready() -> void:
	outro_finished.connect(_on_outro_finished)
	start_outro()


func start_outro() -> void:
	print("OUTRO DIRECTOR INITIALIZED")
	camera.make_current()
	
	# Aseguramos que el overlay empiece invisible y el texto sin letras mostradas
	if screen_overlay and fade_rect:
		screen_overlay.visible = true
		fade_rect.modulate.a = 0.0 
	if texto_final:
		texto_final.visible_characters = 0 # Inicia completamente transparente
	
	await get_tree().process_frame
	await _run_sequence()


func _run_sequence() -> void:
	if not lino_animation:
		print("ERROR: AnimationPlayer node missing.")
		return

	# =========================================================================
	# PHASE 1: TIMELINE PLAYBACK
	# =========================================================================
	lino_animation.play("outro_cinematic")
	
	# Delay timer matching the layout timeline until text execution starts
	await get_tree().create_timer(19.0).timeout

	# =========================================================================
	# PHASE 2: AUTOMATED DIALOGUE LOOP (SEQUENTIAL TAG FLOW)
	# =========================================================================
	var secuencias_dialogo = [
		{"tag": "linea_1", "tiempo": 3.5},
		{"tag": "linea_2", "tiempo": 5.5},
		{"tag": "linea_3", "tiempo": 5.5},
		{"tag": "linea_4", "tiempo": 5.5},
		{"tag": "linea_5", "tiempo": 4.0},
		{"tag": "linea_6", "tiempo": 2.5},
		{"tag": "linea_7", "tiempo": 2.5},
		{"tag": "linea_8", "tiempo": 5.0} 
	]

	for dialogo in secuencias_dialogo:
		DialogueManager.show_dialogue_balloon(DIALOGO_OUTRO, dialogo["tag"])
		await get_tree().create_timer(dialogo["tiempo"]).timeout

	# =========================================================================
	# PHASE 3: SCENE BREAKING (POST-DIALOGUE DELAY)
	# =========================================================================
	# Fix: Poetic 1-second breath room after the last line vanishes
	await get_tree().create_timer(1.0).timeout

	if tilemap_walls:
		tilemap_walls.set_cell(Vector2i(14, 5), -1) 
		
	if tilemap_furnitures:
		tilemap_furnitures.set_cell(Vector2i(14, 6), -1)
		
	# =========================================================================
	# PHASE 4: LOCAL TWEEN FADE-OUT & DRAMATIC TYPING
	# =========================================================================
	print("Starting localized Tween Fade-Out...")
	await _ejecutar_fade_out()

	print("OUTRO SEQUENCE COMPLETE")
	outro_finished.emit()


func _ejecutar_fade_out() -> void:
	if fade_rect:
		fade_rect.modulate.a = 0.0 
		
		# 1. Animamos el fondo negro para que oscurezca la pantalla en 1.5 segundos
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		# Pausa táctica de 0.5 segundos en oscuridad total antes de empezar a escribir
		await get_tree().create_timer(0.5).timeout
		
		# 2. Tipeo automático letra a letra
		if texto_final:
			var total_letras: int = texto_final.text.length()
			var tween_texto := create_tween()
			
			# Multiplicamos el total de caracteres por 0.08 segundos por letra (ajusta para más lento/rápido)
			var duracion_tipeo: float = total_letras * 0.08
			
			tween_texto.tween_property(texto_final, "visible_characters", total_letras, duracion_tipeo)
			await tween_texto.finished
			
			# 3. Respiro solicitado: Pasados exactamente dos segundos, el código continuará
			await get_tree().create_timer(2.0).timeout
	else:
		await get_tree().create_timer(1.5).timeout


# =========================================================================
# SCENE TRANSLATION METHOD
# =========================================================================
func _on_outro_finished() -> void:
	print("REDIRECTING SCENE MECHANICS...")
	var nueva_escena_ruta: String = "res://scenes/quests/lore_quests/quest_000/1_ruined_village/tutorial_ruined_village.tscn"

	if ResourceLoader.exists(nueva_escena_ruta):
		get_tree().change_scene_to_file(nueva_escena_ruta)
	else:
		print("CRITICAL SCENE ROUTE ERROR: ", nueva_escena_ruta)
