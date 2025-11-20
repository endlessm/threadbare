# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends FillingBarrel

# Buscamos el nodo de audio que acabamos de crear
@onready var hit_sound = $AudioStreamPlayer

# Sobrescribimos la función que cuenta los golpes
func increment(by: int = 1) -> void:
	# 1. Llamamos a la lógica original (llenar barra, animaciones, etc.)
	super.increment(by)
	
	# 2. ¡Reproducimos el sonido!
	if hit_sound:
		hit_sound.play()
