# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends VBoxContainer

const QUEST_ROOT := "res://scenes/quests"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	rebuild()


func _on_visibility_changed() -> void:
	if visible:
		rebuild()


func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	for dir: String in DirAccess.get_directories_at(QUEST_ROOT):
		for quest in Quest.enumerate(QUEST_ROOT.path_join(dir)):
			var bits: Array[String]
			if quest.title:
				bits.append(quest.title)
			bits.append(quest.resource_path.get_base_dir().substr(QUEST_ROOT.length() + 1))
			var button := CheckButton.new()
			button.text = " · ".join(bits)
			button.button_pressed = GameState.completed_quests.has(quest.resource_path)
			button.toggled.connect(_on_button_toggled.bind(quest))
			add_child(button)


func _on_button_toggled(toggled_on: bool, quest: Quest) -> void:
	GameState.set_quest_completed_state(quest, toggled_on)
