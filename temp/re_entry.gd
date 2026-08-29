# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@export var slide_offset_y: float = 150.0 # Cantidad de píxeles para el desplazamiento

@onready var label: Label = $Label

# Variable para guardar la posición Y real calculada por la UI
var _base_target_y: float = 0.0
var _is_target_saved: bool = false

func _ready() -> void:
	modulate.a = 0.0

func animate_re_entry(text_content: String, time: int) -> void:
	show()
	label.text = text_content
	
	# Guardar posición base si no se ha guardado
	if not _is_target_saved:
		_base_target_y = position.y
		_is_target_saved = true

	var target_y: float = _base_target_y
	var start_y: float = target_y - abs(slide_offset_y)
	
	position.y = start_y
	modulate.a = 0.0
	
	# ENTRADA
	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(self, "position:y", target_y, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(self, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(time).timeout

	# SALIDA
	var tween_out := create_tween().set_parallel(true)
	tween_out.tween_property(self, "position:y", start_y, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_out.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	await tween_out.finished
	position.y = target_y
	hide()
