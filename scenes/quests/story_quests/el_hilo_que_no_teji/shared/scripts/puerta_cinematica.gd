# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Puerta secreta que una cinemática abre: cambia el dibujo y quita su colisión.


func abrir_puerta_secreta() -> void:
	%DoorClosed.visible = false
	%DoorOpened.visible = true

	if %ColliderWhenClosed.has_node("ShapeWhenClosed"):
		%ColliderWhenClosed.get_node("ShapeWhenClosed").disabled = true

	if has_node("DoorSound"):
		$DoorSound.play()
