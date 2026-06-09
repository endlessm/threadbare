# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var title: Label = %Title
@onready var animated_texture_rect: AnimatedTextureRect = %AnimatedTextureRect
@onready var rich_text_label: RichTextLabel = %RichTextLabel


func _ready() -> void:
	var quest := GameState.quest.quest

	title.text = quest.title
	animated_texture_rect.sprite_frames = quest.sprite_frames
	rich_text_label.text = quest.description

	await get_tree().create_timer(3).timeout

	(
		SceneSwitcher
		. change_to_file_with_transition(
			quest.first_scene,
			^"",
			Transition.Effect.RADIAL,
			Transition.Effect.FADE,
		)
	)
