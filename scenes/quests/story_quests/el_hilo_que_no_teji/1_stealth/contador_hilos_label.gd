# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label

func _process(_delta: float) -> void:
	# Leemos directamente TU estado global, esto no puede fallar
	var hilos_actuales = ElHiloQueNoTejiState.hilos_recogidos
	
	var modulo = hilos_actuales % 3
	
	if hilos_actuales == 0:
		text = "0/3"
	elif modulo == 0:
		# Si el residuo es 0 y tenemos hilos (ej. 3, 6, 9), significa que el pergamino está lleno
		text = "3/3"
	else:
		# Si recogimos 1, 4 o 7, dirá 1/3. Si recogimos 2, 5 u 8, dirá 2/3.
		text = str(modulo) + "/3"
