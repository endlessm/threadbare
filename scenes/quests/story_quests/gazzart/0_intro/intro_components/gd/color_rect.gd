# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasModulate


@export var player_path: NodePath
@onready var player: Player = $"../Player"

func _process(_delta: float) -> void:
	if not player:
		return
	
	var player_x = player.global_position.x
	var opacity := clampf((player_x - 2500.0) / 500.0, 0.0, 1.0)
	# ↑ Aumenta gradualmente entre 2500 y 3000px; puedes ajustar el rango
	
	color.a = opacity
