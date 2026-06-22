# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@onready var label = $Label
@onready var timer = $Label/Timer

func _ready() -> void:
	# Ocultamos todo el panel al inicio
	hide()
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

var texto_completo: String = ""

func mostrar_pensamiento(nuevo_texto: String) -> void:
	texto_completo = nuevo_texto
	
	# 1. Aseguramos que el Label no esté ocultando nada por porcentaje
	label.visible_ratio = 1.0 
	label.text = "" 
	
	# 2. Mostramos el panel de forma opaca
	show()
	modulate.a = 1.0 
	
	# 3. Animamos el crecimiento inyectando letras una por una
	var tween = create_tween()
	tween.tween_method(_escribir_letras, 0, texto_completo.length(), 5.0)
	
	timer.start(6.0)

func _escribir_letras(cantidad_actual: int) -> void:
	label.text = texto_completo.substr(0, cantidad_actual)

func _on_timer_timeout() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(hide)
