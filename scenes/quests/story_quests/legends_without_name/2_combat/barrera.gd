# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

func ocultar_y_desactivar() -> void:
	# Oculta el nodo Barrera 
	hide() 
	
	# Desactiva la colisión 
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
