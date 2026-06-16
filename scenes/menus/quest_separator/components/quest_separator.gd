# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var title: Label = %Title
@onready var animated_texture_rect: AnimatedTextureRect = %AnimatedTextureRect
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var back_button: Button = %BackButton
@onready var play_button: Button = %PlayButton
@onready var auto_play_progress_bar: ProgressBar = %AutoPlayProgressBar
@onready var auto_play_timer: Timer = %AutoPlayTimer


func _ready() -> void:
	var quest := GameState.quest.quest

	title.text = quest.title
	animated_texture_rect.sprite_frames = quest.sprite_frames
	animated_texture_rect.animation_name = quest.animation_name
	rich_text_label.text = quest.description

	play_button.grab_focus()
	play_button.focus_exited.connect(stop_timer, CONNECT_ONE_SHOT)
	play_button.pressed.connect(play)

	back_button.pressed.connect(back)

	auto_play_timer.timeout.connect(play)


func stop_timer() -> void:
	auto_play_timer.stop()


func back() -> void:
	stop_timer()
	# TODO: it is weird to call into the pause overlay from here.
	# Perhaps this separator should itself be part of the "pause" menu hierarchy?
	PauseOverlay.abandon_quest()


func play() -> void:
	stop_timer()
	var quest := GameState.quest.quest
	SceneSwitcher.change_to_file_with_transition(
		quest.first_scene, ^"", Transition.Effect.RADIAL, Transition.Effect.FADE
	)
