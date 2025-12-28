# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name StorybookPage
extends MarginContainer
## A control that displays a [Quest].

## Emitted when the player chooses the quest shown on this page
signal selected(quest: Quest)

## The quest displayed on this page
var quest: Quest = preload("uid://dwl8letaanhhi"):
	set = _set_quest

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var authors: Label = %Authors
@onready var animation: AnimatedTextureRect = %Animation
@onready var play_button: Button = %PlayButton


func _set_quest(new_quest: Quest) -> void:
	quest = new_quest

	if not is_node_ready():
		return

	title.text = quest.title.strip_edges()
	description.text = quest.description.strip_edges()

	match quest.authors.size():
		0:
			authors.text = ""
		1:
			authors.text = "A story by " + quest.authors[0]
		_:
			authors.text = (
				" "
				. join(
					[
						"A story by",
						", ".join(quest.authors.slice(0, -1)),
						"and",
						quest.authors[-1],
					]
				)
			)

	if quest.affiliation:
		authors.text += " of " + quest.affiliation

	animation.sprite_frames = quest.sprite_frames
	animation.animation_name = quest.animation_name


func _ready() -> void:
	_set_quest(quest)
	play_button.pressed.connect(_on_play_button_pressed)


func _on_play_button_pressed() -> void:
	selected.emit(quest)
