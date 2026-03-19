# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerInteraction
extends Node2D

## The character that gains interaction.
## [br][br]
## [b]Note:[/b] If the parent node is a CharacterBody2D and character isn't set,
## the parent node will be automatically assigned to this variable.
@export var character: CharacterBody2D:
	set = _set_character

var is_interacting: bool:
	get = _get_is_interacting

@onready var interact_zone: Area2D = %InteractZone
@onready var interact_marker: Marker2D = %InteractMarker
@onready var interact_label: FixedSizeLabel = %InteractLabel

@onready var player: Player = self.owner as Player


func _set_character(new_character: CharacterBody2D) -> void:
	character = new_character
	update_configuration_warnings()


func _get_is_interacting() -> bool:
	return not interact_zone.monitoring


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not character:
		warnings.append("Character must be set.")
	return warnings


func _process(_delta: float) -> void:
	if is_interacting:
		return

	var interact_area: InteractArea = interact_zone.get_interact_area()
	if not interact_area:
		interact_label.visible = false
	else:
		interact_label.visible = true
		interact_label.label_text = interact_area.action
		interact_marker.global_position = interact_area.get_global_interact_label_position()


func _unhandled_input(_event: InputEvent) -> void:
	if is_interacting:
		return

	var interact_area: InteractArea = interact_zone.get_interact_area()
	if interact_area and Input.is_action_just_pressed(&"interact"):
		# While interacting, this class takes control over the player movement.
		if character.has_method("take_control"):
			character.take_control(self)
			character.velocity = Vector2.ZERO

		get_viewport().set_input_as_handled()
		interact_zone.monitoring = false
		interact_label.visible = false
		interact_area.interaction_ended.connect(_on_interaction_ended, CONNECT_ONE_SHOT)
		interact_area.start_interaction(player, interact_zone.is_looking_from_right)


func _on_interaction_ended() -> void:
	interact_zone.monitoring = true
	# After interacting, return control to the user.
	if character.has_method("return_control"):
		character.return_control(self)
