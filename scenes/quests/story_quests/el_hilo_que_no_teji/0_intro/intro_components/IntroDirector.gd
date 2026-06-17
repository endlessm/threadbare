# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
signal intro_finished

@onready var camera: Camera2D = $"../Camera2D"
@onready var flash_layer: CanvasLayer = $"../FlashOverlay"
@onready var flash_rect: ColorRect = $"../FlashOverlay/ColorRect"
@onready var points: Node2D = $"../CameraPoints"

var steps := [
	"A_Lino_Playing",
	"B_Lino_Sleeping",
	"C_Door_Open",
	"D_Collar_Empty"
]


func start_intro() -> void:
	print("INTRO DIRECTOR FUNCIONA")

	# CRÍTICO: esta cámara pasa a ser la activa
	camera.make_current()

	# aseguramos frame estable antes de empezar
	await get_tree().process_frame

	await _run_sequence()


func _run_sequence() -> void:
	for point_name in steps:
		await _flash_in()

		await _move_camera(point_name)

		await get_tree().create_timer(0.6).timeout

	await _flash_in()
	print("INTRO SECUENCIA TERMINADA")
	intro_finished.emit()


func _move_camera(point_name: String) -> void:
	var target := points.get_node(point_name) as Node2D

	var tween := create_tween()
	tween.tween_property(
		camera,
		"global_position",
		target.global_position,
		0.8
	)

	await tween.finished


func _flash_in() -> void:
	# asegurar estado inicial
	flash_rect.modulate.a = 1.0

	await get_tree().create_timer(0.15).timeout

	flash_rect.modulate.a = 0.0
