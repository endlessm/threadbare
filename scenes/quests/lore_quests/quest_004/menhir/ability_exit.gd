# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var next_scene: String = "res://scenes/quests/lore_quests/quest_004/02-El_que_cuida_lo_que_crece/Casa_con_patas.tscn"
@export var required_ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_C


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	if not GameState.has_ability(required_ability):
		return
	if next_scene.is_empty():
		return
	SceneSwitcher.change_to_file_with_transition.call_deferred(next_scene)
