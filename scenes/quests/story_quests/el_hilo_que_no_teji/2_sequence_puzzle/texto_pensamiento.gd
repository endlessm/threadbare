# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@onready var label = $Label
@onready var timer = $Label/Timer

func _ready() -> void:
	# Reseteamos el texto y ocultamos todo el panel
	label.visible_ratio = 0.0
	hide()
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

func mostrar_pensamiento(nuevo_texto: String) -> void:
	# 1. Inyectamos el texto
	label.text = nuevo_texto
	
	# 2. Curamos cualquier ocultamiento previo
	label.show() 
	label.visible_characters = -1 # -1 significa "mostrar todo" en Godot
	
	# 3. Mostramos el Panel negro
	show() 
	
	# 4. Preparamos la animación
	label.visible_ratio = 0.0
	modulate.a = 1.0 
	
	# Escribe el texto gradualmente a lo largo de 1.5 segundos
	var tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1, 5)
	
	# Arranca el cronómetro para que desaparezca después de 6.5 segundos
	timer.start(6.0)

func _on_timer_timeout() -> void:
	# Desvanece suavemente TODO (fondo y texto)
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(hide)
