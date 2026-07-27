# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var direction: Enums.LookAtSide = Enums.LookAtSide.LEFT:
	set(a_direction):
		direction = a_direction
		if !is_inside_tree():
			return
		update_appearance()

@export_multiline var text: String = "":
	set(a_text):
		text = a_text
		update_label_text()


func _ready() -> void:
	update_appearance()
	update_label_text()

	if Engine.is_editor_hint():
		return

	update_label_visiblity()


func update_appearance() -> void:
	$Appearance.flip_h = direction == Enums.LookAtSide.RIGHT


func _on_area_2d_body_entered(_body: Node2D) -> void:
	update_label_visiblity()


func _on_area_2d_body_exited(_body: Node2D) -> void:
	update_label_visiblity()


func update_label_visiblity() -> void:
	$LabelContainer.visible = !$Area2D.get_overlapping_bodies().is_empty()


func update_label_text() -> void:
	%Label.text = text
