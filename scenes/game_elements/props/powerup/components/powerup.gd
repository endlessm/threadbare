# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D
## A powerup that, when interacted, enables a player ability.
##
## By default it also displays a dialogue telling the player that an ability
## has been obtained.

## Emitted when this powerup is collected.
signal collected

## The player ability to enable.
@export var ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_A

## Name for the ability to display if using the default dialogue.
@export var ability_name: String

## Text to display in the label when the player gets close to interact with this powerup.
@export var interact_action: String:
	set = _set_interact_action

## Asset of this powerup.
@export var sprite_frames: SpriteFrames:
	set = _set_sprite_frames

## The powerup shines with this color through a shader.
@export var highlight_color: Color = Color.WHITE:
	set = _set_highlight_color

## Dialogue to display when collecting the powerup.
@export var dialogue: DialogueResource = preload("uid://cj0i5jwlv8idi")

var _tween: Tween

@onready var interact_area: InteractArea = %InteractArea
@onready var highlight_effect: Sprite2D = %HighlightEffect
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var interact_collision: CollisionShape2D = %InteractCollision
@onready var ground_collision: CollisionShape2D = %GroundCollision


func _set_interact_action(new_interact_action: String) -> void:
	interact_action = new_interact_action
	if is_node_ready():
		interact_area.action = interact_action


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if is_node_ready():
		sprite.sprite_frames = sprite_frames
		sprite.play("default")


func _set_highlight_color(new_highlight_color: Color) -> void:
	highlight_color = new_highlight_color
	if is_node_ready():
		highlight_effect.modulate = highlight_color


func _ready() -> void:
	_set_interact_action(interact_action)
	_set_sprite_frames(sprite_frames)
	_set_highlight_color(highlight_color)
	if Engine.is_editor_hint():
		return
	GameState.abilities_changed.connect(_on_abilities_changed)
	_on_abilities_changed()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# Since this is a tool script that plays the animations in the
			# editor, reset the frame progress before saving the scene.
			sprite.frame_progress = 0


func _on_abilities_changed() -> void:
	var has_ability := GameState.has_ability(ability)
	ground_collision.disabled = has_ability
	interact_collision.disabled = has_ability
	highlight_effect.visible = not has_ability
	var alpha: float = 0.5 if has_ability else 1.0
	sprite.modulate = Color(Color.WHITE, alpha)
	_set_highlight_color(highlight_color)
	var highlight_material := highlight_effect.material as ShaderMaterial
	if highlight_material:
		highlight_material.set_shader_parameter(&"width", 0.4)


func _on_interact_area_interaction_started(
	_player: Player, _from_right: bool, source: InteractArea
) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(highlight_effect, "modulate", Color.WHITE, 0.5)
	_tween.tween_property(highlight_effect, "material:shader_parameter/width", 1.0, 1.0)
	await _tween.finished
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
	source.end_interaction()
	GameState.set_ability(ability, true)
	collected.emit()


func _on_interact_area_observers_changed() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var width: float = 0.8 if interact_area.is_being_observed else 0.4
	_tween.tween_property(highlight_effect, "material:shader_parameter/width", width, 1.0)
