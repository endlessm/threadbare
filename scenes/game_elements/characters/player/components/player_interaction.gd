# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerInteraction
extends Node2D

## Emitted when the entity the player is able to interact with changes (possibly
## to nothing).
signal interact_action_changed

## The character that gains interaction.
## [br][br]
## [b]Note:[/b] If the parent node is a CharacterBody2D and character isn't set,
## the parent node will be automatically assigned to this variable.
@export var character: CharacterBody2D:
	set = _set_character

@onready var character_sight: CharacterSight = %CharacterSight

@onready var player: Player = self.owner as Player


func _set_character(new_character: CharacterBody2D) -> void:
	character = new_character
	update_configuration_warnings()


## Returns the human-readable text of [member character]'s current interact
## action (e.g. [code]"Talk"[/code]), or [code]""[/code] (empty string) if
## [member character] cannot currently interact with anything. Use [signal
## interact_action_changed] to monitor for changes.
func get_interact_action() -> String:
	if character_sight.interact_area != null:
		var action := character_sight.interact_area.action
		return action if action else tr("Interact")
	return ""


func _is_interacting() -> bool:
	return not character_sight.monitoring


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not character:
		warnings.append("Character must be set.")
	return warnings


func _ready() -> void:
	character_sight.interact_area_changed.connect(_on_character_sight_interact_area_changed)
	_on_character_sight_interact_area_changed()


func _unhandled_input(_event: InputEvent) -> void:
	if _is_interacting():
		return

	var interact_area := character_sight.interact_area
	if interact_area and Input.is_action_just_pressed(&"interact"):
		# While interacting, this class takes control over the player movement.
		if character.has_method("take_control"):
			character.take_control(self)
			character.velocity = Vector2.ZERO

		get_viewport().set_input_as_handled()
		character_sight.monitoring = false
		interact_area.interaction_ended.connect(_on_interaction_ended, CONNECT_ONE_SHOT)
		interact_area.start_interaction(player, character_sight.is_looking_from_right)


func _on_interaction_ended() -> void:
	character_sight.monitoring = true
	# After interacting, return control to the user.
	if character.has_method("return_control"):
		character.return_control(self)


func _on_character_sight_interact_area_changed() -> void:
	interact_action_changed.emit()
