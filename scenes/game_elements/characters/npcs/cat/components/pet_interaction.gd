# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var interact_area: InteractArea
@export var miaow_player: AudioStreamPlayer2D


func _ready() -> void:
	interact_area.interaction_started.connect(_on_interact_area_interaction_started)


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	interact_area.end_interaction()
	interact_area.disabled = true
	miaow_player.play()
	await miaow_player.finished
	interact_area.disabled = false
