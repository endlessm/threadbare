# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var title: Label = %Title
@onready var animated_texture_rect: AnimatedTextureRect = %AnimatedTextureRect
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var back_button: Button = %BackButton
@onready var restart_button: Button = %RestartButton
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
	if quest.resource_path in GameState.global.suspended_quests:
		restart_button.pressed.connect(play, CONNECT_ONE_SHOT)

		play_button.text = tr("Continue")
		play_button.pressed.connect(restore, CONNECT_ONE_SHOT)
		auto_play_timer.timeout.connect(restore, CONNECT_ONE_SHOT)
	else:
		restart_button.hide()
		play_button.pressed.connect(play, CONNECT_ONE_SHOT)
		auto_play_timer.timeout.connect(play, CONNECT_ONE_SHOT)

		if quest in GameState.global.completed_quests:
			play_button.text = tr("Replay")

	back_button.pressed.connect(back, CONNECT_ONE_SHOT)


func stop_timer() -> void:
	auto_play_timer.stop()


func back() -> void:
	stop_timer()

	# TODO: it is weird to call into the pause overlay from here.
	# Perhaps this separator should itself be part of the "pause" menu hierarchy?
	PauseOverlay.abandon_quest(false)


## Restores the current quest
func restore() -> void:
	stop_timer()

	GameState.restore_quest()
	# Now GameState.scene has been restored, jump to the scene & spawn point it
	# describes
	SceneSwitcher.change_to_file_with_transition(
		GameState.scene.path,
		GameState.scene.spawn_point,
		Transition.Effect.RADIAL,
		Transition.Effect.FADE
	)


## Starts the current quest from the beginning
func play() -> void:
	stop_timer()
	var quest := GameState.quest.quest

	# If there was a previous abandoned attempt at this quest, discard it.
	GameState.global.suspended_quests.erase(quest.resource_path)

	SceneSwitcher.change_to_file_with_transition(
		quest.first_scene, ^"", Transition.Effect.RADIAL, Transition.Effect.FADE
	)
