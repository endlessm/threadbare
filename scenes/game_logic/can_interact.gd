# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool

## Enable the character to interact with interactible areas of the world.
class_name CanInteract
extends Node2D

@export var interact_zone: Area2D
@export var interact_marker: Marker2D
@export var interact_label: FixedSizeLabel

var is_interacting: bool:
	get = _get_is_interacting

# TODO: Add configuration warning to the node if the parent is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	print("%s: I can interact" % character.name)


func _physics_process(_delta: float) -> void:
	if is_interacting:
		return

	var interact_area: InteractAreaNew = get_interact_area()
	if not interact_area:
		interact_label.visible = false
	else:
		interact_label.visible = true
		interact_label.label_text = interact_area.action
		interact_marker.global_position = interact_area.get_global_interact_label_position()

	if not is_zero_approx(character.velocity.x):
		if character.velocity.x < 0:
			scale.x = -1
		else:
			scale.x = 1


func _unhandled_input(_event: InputEvent) -> void:
	if is_interacting:
		return

	var interact_area: InteractAreaNew = get_interact_area()
	if interact_area and Input.is_action_just_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		interact_zone.monitoring = false
		interact_label.visible = false
		interact_area.interaction_ended.connect(_on_interaction_ended, CONNECT_ONE_SHOT)
		interact_area.start_interaction(character, character.look_at_side == Enums.LookAtSide.RIGHT)


func _get_is_interacting() -> bool:
	return not interact_zone.monitoring


func _on_interaction_ended() -> void:
	interact_zone.monitoring = true


func get_interact_area() -> InteractAreaNew:
	var areas := interact_zone.get_overlapping_areas()
	var best: InteractAreaNew = null
	var best_distance: float = INF

	for area in areas:
		var distance := interact_zone.global_position.distance_to(area.global_position)
		if not best or distance < best_distance:
			best_distance = distance
			best = area

	return best
