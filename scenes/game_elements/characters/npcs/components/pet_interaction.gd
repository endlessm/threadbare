# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var interact_area: InteractArea
@export var sound_effect_player: AudioStreamPlayer2D
@export var shaker: Shaker
@export var achievement_counter: AchievementCounter


func _ready() -> void:
	interact_area.interaction_started.connect(_on_interact_area_interaction_started)


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	interact_area.end_interaction()
	interact_area.disabled = true
	sound_effect_player.play()
	if shaker:
		shaker.shake()
	if achievement_counter:
		achievement_counter.add_achievement()
	await sound_effect_player.finished
	interact_area.disabled = false
