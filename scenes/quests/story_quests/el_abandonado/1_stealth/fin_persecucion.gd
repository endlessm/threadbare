# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@onready var camara = $"../Camera2D"
@onready var lich = $"../Enemy"

func _on_body_entered(body):

	if body.name == "Player":
		camara.persecucion_activa = false
		lich.desaparecer()
