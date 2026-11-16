# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D

func _input(event):
	if event.is_action_pressed("interact"):
		SceneSwitcher.change_to_file("res://scenes/quests/story_quests/shjourney/2_shjourney_intro/template_intro.tscn")
