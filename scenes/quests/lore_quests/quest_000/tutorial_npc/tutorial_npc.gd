# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CharacterRandomizer

## Dialogue to play when the player interacts with this NPC.
@export var dialogue: DialogueResource:
	set(new_value):
		dialogue = new_value
		if talk_behavior:
			talk_behavior.dialogue = new_value

## Title of [member dialogue] to play when the player interacts with this NPC.
@export var dialogue_title: StringName = &"start":
	set(new_value):
		dialogue_title = new_value
		if talk_behavior:
			talk_behavior.title = dialogue_title

## The path to follow when calling [method walk_path].
@export var path: Path2D:
	set(new_value):
		path = new_value
		if path_walk_behavior:
			path_walk_behavior.walking_path = new_value

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior
@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior


func _ready() -> void:
	dialogue = dialogue
	dialogue_title = dialogue_title
	path = path


## Walk along [member path], disabling interactions until the end of the path is
## reached.
func walk_path() -> void:
	interact_area.disabled = true
	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT

	await path_walk_behavior.ending_reached

	interact_area.disabled = false
	path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	path_walk_behavior.character.velocity = Vector2.ZERO
