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
@onready var texto_final: RichTextLabel = $"../ScreenOverlay/ColorRect/RichTextLabel"

const DIALOGO_OUTRO = preload("res://scenes/quests/story_quests/el_hilo_que_no_teji/4_outro/outro_components/el_hilo_que_no_teji_outro.dialogue")

# NODOS DE AUDIO (Asegúrate de crearlos como hijos del OutroDirector si los vas a usar)
@onready var sonido_rasgunos: AudioStreamPlayer = $SonidoRasgunos
@onready var sonido_ladrido: AudioStreamPlayer = $SonidoLadrido

var camara_siguiendo: bool = false
var velocidad_camara: float = 1.0 # Inicia en 1.0 para teletransportarse a Lino al cuadro 0

func _ready() -> void:
	outro_finished.connect(_on_outro_finished)
	start_outro()

func _physics_process(_delta: float) -> void:
	# SEGUIMIENTO TOTAL: La cámara sigue a Lino DESDE EL PRINCIPIO
	if camara_siguiendo:
		var lino_nodo = $"../OnTheGround/Lino"
		if lino_nodo:
			camera.global_position = camera.global_position.lerp(lino_nodo.global_position, velocidad_camara)

func start_outro() -> void:
	print("OUTRO DIRECTOR INITIALIZED")
	
	# Forzamos a la cámara a centrarse instantáneamente en Lino antes de que empiece la secuencia
	camara_siguiendo = true
	velocidad_camara = 1.0 # Movimiento instantáneo sin retraso
	camera.make_current()
	
	if screen_overlay and fade_rect:
		screen_overlay.visible = true
		fade_rect.modulate.a = 0.0 
	if texto_final:
		texto_final.visible_characters = 0
	
	await get_tree().process_frame
	
	# Cambiamos la velocidad a una suave (0.05) para cuando Lino empiece a caminar más adelante
	velocidad_camara = 0.05 
	await _run_sequence()

func _run_sequence() -> void:
	if not lino_animation:
		print("ERROR: AnimationPlayer node missing.")
		return

	# =========================================================================
	# PHASE 1: TIMELINE PLAYBACK & SUSPENSE SOUNDS (CÁMARA YA CENTRADA EN SOFÁ)
	# =========================================================================
	lino_animation.play("outro_cinematic")
	
	# EFECTO 1: A los 2 segundos, Lino sigue desmayado y se oyen los rasguños en la puerta
	await get_tree().create_timer(2.0).timeout
	if sonido_rasgunos:
		sonido_rasgunos.play()
	
	# Esperamos el resto del tiempo de la animación (19.0 - 2.0 = 17.0)
	# Durante todo este tiempo, como Lino está quieto en el sofá, la cámara se queda fija sobre él
	await get_tree().create_timer(17.0).timeout

	# =========================================================================
	# PHASE 2: AUTOMATED DIALOGUE (LINO CAMINA Y LA CÁMARA LO ACOMPAÑA SUAVEMENTE)
	# =========================================================================
	DialogueManager.show_dialogue_balloon(DIALOGO_OUTRO, "start")
	await DialogueManager.dialogue_ended

	# =========================================================================
	# PHASE 3: SCENE BREAKING & THE REVELATION (ABRIR PUERTA)
	# =========================================================================
	await get_tree().create_timer(1.5).timeout

	# Borramos la puerta de los Tilemaps
	if tilemap_walls:
		tilemap_walls.set_cell(Vector2i(14, 5), -1) 
	if tilemap_furnitures:
		tilemap_furnitures.set_cell(Vector2i(14, 6), -1)
		
	# EFECTO 2: La puerta se desvanece y Manchitas ladra de alegría
	if sonido_ladrido:
		sonido_ladrido.play()
		
	# Congelamos la cámara en esa posición final para enfocar el reencuentro de Lino y Manchitas
	camara_siguiendo = false

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
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		await get_tree().create_timer(0.5).timeout
		
		if texto_final:
			var total_letras: int = texto_final.text.length()
			var tween_texto := create_tween()
			var duracion_tipeo: float = total_letras * 0.08
			
			tween_texto.tween_property(texto_final, "visible_characters", total_letras, duracion_tipeo)
			await tween_texto.finished
			
			await get_tree().create_timer(2.0).timeout
	else:
		await get_tree().create_timer(1.5).timeout

func _on_outro_finished() -> void:
	print("REDIRECTING SCENE MECHANICS...")
	var nueva_escena_ruta: String = "res://scenes/world_map/frays_end.tscn"

	if ResourceLoader.exists(nueva_escena_ruta):
		get_tree().change_scene_to_file(nueva_escena_ruta)
	else:
		print("CRITICAL SCENE ROUTE ERROR: ", nueva_escena_ruta)
