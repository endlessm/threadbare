# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

func abrir_puerta_secreta() -> void:
	# 1. Ocultamos la versión cerrada y mostramos la abierta de inmediato
	%DoorClosed.visible = false
	%DoorOpened.visible = true
	
	# 2. CORRECCIÓN DE COLISIÓN: 
	# Buscamos el nodo hijo real 'ShapeWhenClosed' que está dentro de ColliderWhenClosed
	if %ColliderWhenClosed.has_node("ShapeWhenClosed"):
		%ColliderWhenClosed.get_node("ShapeWhenClosed").disabled = true
	
	# 3. Reproducemos el sonido si existe el nodo DoorSound
	if has_node("DoorSound"):
		$DoorSound.play()
