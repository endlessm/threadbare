# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var interact_area = $NtlPapers/InteractArea
@onready var area_phone = $NtlPhone/InteractArea
@onready var sprite_2d = $NtlPapers

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_update_based_on_revealed()
		
func _ready() -> void:
	if area_phone.has_signal("interaction_ended"):
		area_phone.interaction_ended.connect(reveal)
		
	if interact_area.has_signal("interaction_ended"):
		interact_area.interaction_ended.connect(finish)
	
func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
	
func reveal() -> void:
	revealed = true
	area_phone.disabled = true
	
func finish() -> void:
	if next_scene:
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				spawn_point_path,
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)
	
