# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CharacterSight
extends Area2D
## The area of sight of the character.
##
## The character sees one [InteractArea] at a time to interact.
## This area also faces toward the character current direction.
## [br][br]
## This script automatically configures the correct [member collision_layer] and
## [member collision_mask] values to enable interaction with the player.

## Emitted when [member interact_area] changes.
signal interact_area_changed

## The character.
@export var character: CharacterBody2D

## The direction the character is facing.
## [br][br]
## TODO: Use east/west instead of right/left?
var is_looking_from_right: bool = false

## The area that the character is currently observing.
var interact_area: InteractArea:
	set = _set_interact_area


func _set_interact_area(new_interact_area: InteractArea) -> void:
	if interact_area:
		interact_area.remove_observer(self)
	interact_area = new_interact_area
	if new_interact_area:
		interact_area.add_observer(self)


func _ready() -> void:
	if not character and owner is CharacterBody2D:
		character = owner
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(Enums.CollisionLayers.INTERACTABLE, true)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _get_best_interact_area() -> InteractArea:
	if not monitoring:
		return null
	var areas := get_overlapping_areas()
	var best: InteractArea = null
	var best_distance: float = INF

	# TODO: This picks the closest area according to their global position,
	# which could be misleading. An Area2D may have a collision shape
	# that is far away from it's anchor.
	for area in areas:
		var distance := global_position.distance_to(area.global_position)
		if not best or distance < best_distance:
			best_distance = distance
			best = area

	return best


func _process(_delta: float) -> void:
	if not character:
		return
	# Flip this area according to the character current direction:
	if not is_zero_approx(character.velocity.x):
		if character.velocity.x < 0:
			scale.x = -1
		else:
			scale.x = 1
		is_looking_from_right = scale.x < 0


func _on_area_entered(_area: Area2D) -> void:
	interact_area = _get_best_interact_area()
	interact_area_changed.emit()


func _on_area_exited(_area: Area2D) -> void:
	interact_area = _get_best_interact_area()
	interact_area_changed.emit()
