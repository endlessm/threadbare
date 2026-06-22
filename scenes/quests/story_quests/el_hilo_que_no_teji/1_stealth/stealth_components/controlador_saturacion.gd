# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ColorRect

const SHADER_PARAM_NAME = "saturation" 

func _process(_delta: float) -> void:
	# Leemos EXCLUSIVAMENTE el valor del estado global del mundo
	var sat_actual = ElHiloQueNoTejiState.world_saturation
	
	# Normalizamos el valor (de 0.0 a 1.0) para que el shader lo entienda
	var sat_normalizada = sat_actual / 100.0
	
	# Le enviamos el valor actualizado al material en cada frame
	if material is ShaderMaterial:	
		material.set_shader_parameter(SHADER_PARAM_NAME, sat_normalizada)
