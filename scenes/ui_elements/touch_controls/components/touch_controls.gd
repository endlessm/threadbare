# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine
@export var displaying_dialogue: bool


func _ready() -> void:
	Transitions.started.connect(update_visibility)
	Transitions.finished.connect(update_visibility)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			update_visibility()


func update_visibility() -> void:
	visible = (
		DisplayServer.is_touchscreen_available()
		and not get_tree().paused
		and not Transitions.is_running()
		and not displaying_dialogue
		and (player or sokoban_ruleset)
	)
