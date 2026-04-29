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

const INDICATOR_SCENE := preload("uid://d252j2mhya0kq")

## Position at which to show an arrow when this area is being observed. This
## should generally be centred, slightly above the visible extents of the parent
## object. If not set, a default position will be used, which may be good enough.
@export var marker: Marker2D:
	set(new_value):
		if marker and _indicator:
			marker.remove_child(_indicator)
		marker = new_value
		if marker and _indicator:
			marker.add_child(_indicator)

@export var disabled: bool = false:
	set(new_value):
		disabled = new_value
		set_collision_layer_value(Enums.CollisionLayers.INTERACTABLE, not disabled)
		if _indicator:
			_indicator.visible = not disabled

@export var action: String = "Talk"

## Whether this area is being observed by one or more characters.
## That is, if a [CharacterSight] area is seeing this area for interaction.
var is_being_observed: bool:
	get = _get_is_being_observed

var _observers: Array[CharacterSight] = []

var _indicator: Node2D


func start_interaction(player: Player, from_right: bool) -> void:
	interaction_started.emit(player, from_right)


func end_interaction() -> void:
	interaction_ended.emit()


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

	if not marker and not Engine.is_editor_hint():
		marker = Marker2D.new()
		marker.name = "Marker"
		# Vaguely sensible default position
		marker.position = Vector2(0, -64)
		add_child(marker)

	_indicator = INDICATOR_SCENE.instantiate()
	if marker:
		marker.add_child(_indicator)

	observers_changed.connect(_on_observers_changed)


func _on_observers_changed() -> void:
	_indicator.bouncing = is_being_observed
