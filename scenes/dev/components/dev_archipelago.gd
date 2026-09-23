# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var bridge_to_frays_end: ToggleableTileMapLayer = %BridgeToFraysEnd
@onready var bridge_to_frays_end_broken: ToggleableTileMapLayer = %BridgeToFraysEndBroken
@onready var story_quest_elder: Elder = %StoryQuestElder


func _ready() -> void:
	# In the stripped-back StoryQuest kit, this is the home scene and Fray's End
	# is not present.
	var home_scene: String = ThreadbareProjectSettings.get_setting(
		ThreadbareProjectSettings.HOME_SCENE
	)
	var is_storyquest_kit := ResourceUID.ensure_path(home_scene) == scene_file_path

	# Conditionally block the route back to Fray's End
	bridge_to_frays_end.set_toggled(is_storyquest_kit)
	bridge_to_frays_end_broken.set_toggled(not is_storyquest_kit)

	if GameState.quest:
		# The player has returned here after completing a quest. There is no
		# loom to interact with: just have an elder congratulate the player.
		await story_quest_elder.congratulate_player()
		GameState.mark_quest_completed()
		GameState.save()

	if not is_storyquest_kit:
		# Don't need the StoryQuest Elder here in the normal project.
		story_quest_elder.queue_free()
		story_quest_elder = null
