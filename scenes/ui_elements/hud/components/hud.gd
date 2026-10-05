# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var re_entry: PanelContainer = %ReEntry


func _ready() -> void:
	GameState.global.zone_changed.connect(_on_zone_changed)


func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility


func _on_zone_changed(zone_name: String, first_visit: bool) -> void:
	if GameState.scene.zone_name_displayed == zone_name:
		return
	GameState.scene.zone_name_displayed = zone_name
	if first_visit:
		await _show_first_unlock(zone_name)
	else:
		await show_re_entry_zone(zone_name)


func _show_first_unlock(zone_name: String) -> void:
	# TODO: Don't instantiate it here.
	var first_unlock: Control = (
		preload("res://scenes/ui_elements/zone_activation/first_unlock.tscn").instantiate()
	)

	add_child(first_unlock)

	await first_unlock.animate_first_unlock(zone_name, 2)

	first_unlock.queue_free()


func show_re_entry_zone(zone_name: String) -> void:
	await re_entry.animate_re_entry(zone_name, 2)
