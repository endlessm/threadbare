# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_A

@export var interact_action: String:
	set = _set_interact_action

@export var sprite_frames: SpriteFrames:
	set = _set_sprite_frames

@onready var interact_area: InteractArea = %InteractArea
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_interact_action(new_interact_action: String) -> void:
	interact_action = new_interact_action
	if is_node_ready():
		interact_area.action = interact_action


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if is_node_ready():
		animated_sprite_2d.sprite_frames = sprite_frames
		animated_sprite_2d.play("default")


func _ready() -> void:
	_set_interact_action(interact_action)
	_set_sprite_frames(sprite_frames)


func _on_interact_area_interaction_started(
	_player: Player, _from_right: bool, source: InteractArea
) -> void:
	GameState.set_ability(ability, true)
	source.end_interaction()
	queue_free()
