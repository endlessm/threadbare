# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
signal outro_finished

@onready var camera: Camera2D = $"../Camera2D"
@onready var flash_layer: CanvasLayer = $"../FlashOverlay"
@onready var flash_rect: ColorRect = $"../FlashOverlay/ColorRect"

@onready var lino_animation: AnimationPlayer = $"../OnTheGround/AnimationPlayer"
@onready var tilemap_walls: TileMapLayer = $"../CabanaParedes"
@onready var tilemap_furnitures: TileMapLayer = $"../Furnitures"


func _ready() -> void:
	outro_finished.connect(_on_outro_finished)
	
	start_outro()


func start_outro() -> void:
	print("OUTRO DIRECTOR FUNCIONA EN PLANO FIJO")
	camera.make_current()
	flash_rect.modulate.a = 0.0
	
	if lino_animation:
		lino_animation.stop()
		
	await get_tree().process_frame
	await _run_sequence()


func _run_sequence() -> void:
	# =========================================================================
	# FASE 1: REPRODUCCIÓN DE LA CINEMÁTICA PRINCIPAL
	# =========================================================================
	if lino_animation:
		lino_animation.play("outro_cinematic")
		
		await lino_animation.animation_finished
	else:
		print("ERROR: No se encontró el AnimationPlayer en la ruta especificada.")

	# =========================================================================
	# FASE 2: AJUSTES FINALES DEL ENTORNO (Puerta abierta / Perro)
	# =========================================================================
	await _flash_in()
	
	if tilemap_walls:
		tilemap_walls.set_cell(Vector2i(14, 5), -1) 
		
	if tilemap_furnitures:
		tilemap_furnitures.set_cell(Vector2i(14, 6), -1)
		
	await get_tree().create_timer(1.0).timeout

	print("OUTRO SECUENCIA TERMINADA")
	
	outro_finished.emit()


func _flash_in() -> void:
	flash_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, 0.4)
	await tween.finished


# =========================================================================
# CAMBIO DE ESCENA AUTOMÁTICO
# =========================================================================
func _on_outro_finished() -> void:
	print("CAMBIANDO AL NIVEL DE STEALTH...")

	var nueva_escena_ruta: String = "res://scenes/quests/lore_quests/quest_000/1_ruined_village/tutorial_ruined_village.tscn"

	if ResourceLoader.exists(nueva_escena_ruta):
		get_tree().change_scene_to_file(nueva_escena_ruta)
	else:
		print("ERROR CRÍTICO: No se encontró el archivo de escena en: ", nueva_escena_ruta)
