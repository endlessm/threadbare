# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name EchoAbyssEssenceNpc
extends CharacterBody2D

@export var dialogue: DialogueResource
@export var dialogue_title: String = "start"
@export var interact_action: String = "Talk"
@export_range(0, 100, 1) var essence_reward: int = 10
@export var award_once: bool = true
@export var sprite_frames: SpriteFrames:
	set(new_sprite_frames):
		sprite_frames = new_sprite_frames
		if _animated_sprite:
			_animated_sprite.sprite_frames = sprite_frames

var _has_awarded_essence := false

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _interact_area: InteractArea = %InteractArea


func _ready() -> void:
	if sprite_frames:
		_animated_sprite.sprite_frames = sprite_frames
	if not Engine.is_editor_hint():
		_interact_area.action = interact_action
		_interact_area.interaction_started.connect(_on_interaction_started)


func _on_interaction_started(player: Player, _from_right: bool) -> void:
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	if _can_award_essence(player):
		player.call("add_essence", essence_reward)
		_has_awarded_essence = true

	_interact_area.end_interaction()


func _can_award_essence(player: Player) -> bool:
	if essence_reward <= 0:
		return false
	if award_once and _has_awarded_essence:
		return false
	return player.has_method("add_essence")
