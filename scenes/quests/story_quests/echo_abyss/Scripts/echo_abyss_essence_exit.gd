# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name EchoAbyssEssenceExit
extends CharacterBody2D

@export var player_path: NodePath
@export var dialogue: DialogueResource
@export var dialogue_title: String = "start"
@export var next_scene: String
@export_range(1, 100, 1) var required_essence: int = 100
@export var sprite_frames: SpriteFrames:
	set(new_sprite_frames):
		sprite_frames = new_sprite_frames
		if _animated_sprite:
			_animated_sprite.sprite_frames = sprite_frames

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _interact_area: InteractArea = %InteractArea


func _ready() -> void:
	if sprite_frames:
		_animated_sprite.sprite_frames = sprite_frames
	if Engine.is_editor_hint():
		return

	_interact_area.disabled = true
	_interact_area.interaction_started.connect(_on_interaction_started)

	var player := get_node_or_null(player_path)
	if player == null:
		push_warning("Echo Abyss essence exit needs a player_path.")
		_set_unlocked(false)
		return

	if player.has_signal("essence_changed"):
		player.connect("essence_changed", Callable(self, "_on_player_essence_changed"))

	var current_essence := 0
	if player.has_method("get_current_essence"):
		current_essence = player.call("get_current_essence")
	_set_unlocked(current_essence >= required_essence)


func _on_player_essence_changed(current_essence: int, _max_essence: int) -> void:
	_set_unlocked(current_essence >= required_essence)


func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self, _player])
		await DialogueManager.dialogue_ended

	_interact_area.end_interaction()
	if not next_scene.is_empty():
		SceneSwitcher.change_to_file_with_transition(
			next_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)


func _set_unlocked(is_unlocked: bool) -> void:
	visible = is_unlocked
	process_mode = Node.PROCESS_MODE_INHERIT if is_unlocked else Node.PROCESS_MODE_DISABLED
	if _interact_area:
		_interact_area.disabled = not is_unlocked
