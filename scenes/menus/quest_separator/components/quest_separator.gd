# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var title: Label = %Title
@onready var animated_texture_rect: AnimatedTextureRect = %AnimatedTextureRect
@onready var rich_text_label: RichTextLabel = %RichTextLabel


func _ready() -> void:
	var quest := GameState.current_quest
	title.text = quest.title
	animated_texture_rect.sprite_frames = quest.sprite_frames
	rich_text_label.text = quest.description

	await get_tree().create_timer(3).timeout

	(
		SceneSwitcher
		. change_to_file_with_transition(
			GameState._quest_scene_path,
			GameState._quest_spawn_point,
			Transition.Effect.RADIAL,
			Transition.Effect.FADE,
		)
	)
