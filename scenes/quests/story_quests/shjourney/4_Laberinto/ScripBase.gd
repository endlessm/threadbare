# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# Señal para comunicarse con el HUD
signal llave_recolectada(llaves_actuales, llaves_maximas)

func _ready():
	$CamaraPuerta/InteractInput.visible = false
	# Conectar la señal con el HUD
	var hud = get_node("Player/Camera2D/HUDKEYS")  # Ajusta la ruta según tu estructura
	if hud:
		connect("llave_recolectada", hud.handleKeyCollector)
	
	# Emitir señal inicial para mostrar 0/3
	emit_signal("llave_recolectada", llaves, llaves_maximas)

var llaves: int = 0
@export var llaves_maximas: int = 3
@onready var puerta: StaticBody2D = $Puerta

func ActualizarLlaves():
	# Emitir señal para actualizar HUD
	emit_signal("llave_recolectada", llaves, llaves_maximas)
	
	if llaves >= llaves_maximas:
		puerta.queue_free()

func _on_timer_puerta_timeout() -> void:
	$"CamaraPuerta".enabled = false
	$"Player/Camera2D".enabled = true
	$CamaraPuerta/InteractInput.visible = false
