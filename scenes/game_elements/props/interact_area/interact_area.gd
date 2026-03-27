# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InteractArea
extends Area2D
## An area that the player-character can interact with
##
## To make an interactable object, add an [InteractArea] to it, and handle
## [signal interaction_started]. When the interaction is complete, call [method
## end_interaction]. This area is detected by character's [CharacterSight];
## the player scene is typically responsible for calling [method
## start_interaction] in response to player input.
## [br][br]
## This script automatically configures the correct [member collision_layer] and
## [member collision_mask] values to enable interaction with the player.

signal interaction_started(player: Player, from_right: bool)
signal interaction_ended

## Emitted when characters start or stop seeing this area for interaction.
signal observers_changed

const EXAMPLE_INTERACTION_FONT = preload("uid://c3bb7lmvdqc5e")
const EXAMPLE_INTERACTION_FONT_SIZE = 34

## Vector2 that approximates the position in which the interact label would
## appear when a player is close.
@export_custom(PROPERTY_HINT_RANGE, "-200,200,1,suffix:px,or_greater,or_less")
var interact_label_position: Vector2:
	set(new_value):
		interact_label_position = new_value
		queue_redraw()
@export var disabled: bool = false:
	set(new_value):
		disabled = new_value
		set_collision_layer_value(Enums.CollisionLayers.INTERACTABLE, not disabled)
@export var action: String = "Talk"

## Whether this area is being observed by one or more characters.
## That is, if a [CharacterSight] area is seeing this area for interaction.
var is_being_observed: bool:
	get = _get_is_being_observed

var _observers: Array[CharacterSight] = []


func start_interaction(player: Player, from_right: bool) -> void:
	interaction_started.emit(player, from_right)


func end_interaction() -> void:
	interaction_ended.emit()


func get_global_interact_label_position() -> Vector2:
	return to_global(interact_label_position)


## A [CharacterSight] calls this when it starts seeing this area.
func add_observer(character_sight: CharacterSight) -> void:
	_observers.append(character_sight)
	observers_changed.emit()


## A [CharacterSight] calls this when it stops seeing this area.
func remove_observer(character_sight: CharacterSight) -> void:
	_observers.erase(character_sight)
	observers_changed.emit()


func _get_is_being_observed() -> bool:
	return bool(_observers.size())


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	# Initialise interactable bit in collision_layer
	disabled = disabled


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var string_size := EXAMPLE_INTERACTION_FONT.get_string_size(
		action, HORIZONTAL_ALIGNMENT_LEFT, -1, EXAMPLE_INTERACTION_FONT_SIZE
	)
	var draw_position := (
		interact_label_position - Vector2(string_size.x, -string_size.y * 2.0) / 2.0
	)
	draw_string(
		EXAMPLE_INTERACTION_FONT,
		draw_position,
		action,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		EXAMPLE_INTERACTION_FONT_SIZE
	)
	draw_string_outline(
		EXAMPLE_INTERACTION_FONT,
		draw_position,
		action,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		EXAMPLE_INTERACTION_FONT_SIZE,
		1,
		Color.BLACK
	)
