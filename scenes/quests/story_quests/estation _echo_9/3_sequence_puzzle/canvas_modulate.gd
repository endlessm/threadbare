# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasModulate

@export var tiempo_total: float = 10.0  # Tiempo total de transición en segundos

var tiempo_transcurrido: float = 0.0
var color_inicial: Color = Color.WHITE
var color_final: Color = Color("242424")


func _ready() -> void:
	color = color_inicial


func _process(delta: float) -> void:
	tiempo_transcurrido += delta
	
	# Calculamos el progreso (0.0 a 1.0)
	var progreso: float = clamp(tiempo_transcurrido / tiempo_total, 0.0, 1.0)
	
	# Interpolamos linealmente entre los colores
	color = color_inicial.lerp(color_final, progreso)
	
	# Opcional: Detener el proceso cuando llegue al color final
	if progreso >= 1.0:
		set_process(false)
