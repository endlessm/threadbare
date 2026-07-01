# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Camera2D

@export var velocidad_scroll := 300.0
@onready var jugador = $"../Player"

var persecucion_activa := false

func _process(delta):

	if persecucion_activa:
		global_position.x += velocidad_scroll * delta
	else:
		global_position = jugador.global_position
