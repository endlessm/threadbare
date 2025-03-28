# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
extends Control

## Dialogue introducing the world
@export var introduction: DialogueResource = preload("res://scenes/intro/intro.dialogue")

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.show_dialogue_balloon(introduction, "", [self])


func start_fade() -> void:
	animation_player.play(&"introduction")


func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	get_tree().change_scene_to_packed(preload("res://scenes/main.tscn"))
