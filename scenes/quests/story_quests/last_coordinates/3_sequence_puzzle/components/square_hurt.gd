# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

signal daño
@export_range(0,64,1.0) var Size:float = 64:
	set(setSize):
		Size = setSize
		update_size()

func _ready() -> void:	
	%AnimationPlayer.play("impact")

func update_size() -> void:
	%Colision.shape.size.x = Size
	%Colision.shape.size.y = Size

func _on_area_2d_body_entered(_body: Node2D) -> void:
	print("daño")
	daño.emit()

func activar_colision() -> void :
	%Area2D.monitoring = true

func desactivar_colision() -> void:
	$Area2D.monitoring = false
