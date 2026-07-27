# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var fill_game_logic: FillGameLogic = %FillGameLogic
@onready var fisherman: Talker = %Fisherman


func _ready() -> void:
	fisherman.interact_area.interaction_ended.connect(
		_on_fisherman_interaction_ended, CONNECT_ONE_SHOT
	)


func _on_fisherman_interaction_ended() -> void:
	fill_game_logic.start()
