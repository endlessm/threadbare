# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

enum Frame {
	NON_DIRECTIONAL = 0,
	LEFT_AND_RIGHT = 1,
}

## Theme type variation of the label when [member Settings.large_text] is on.
## It uses Jersey 15 instead of Jersey 10, at the size where it's crisp.
const LARGE_TEXT_TYPE_VARIATION := &"LargeSignLabel"

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

	if Settings.large_text:
		%Label.theme_type_variation = LARGE_TEXT_TYPE_VARIATION

	update_label_visiblity()


func update_appearance() -> void:
	if direction == Enums.LookAtSide.UNSPECIFIED:
		%Appearance.frame = Frame.NON_DIRECTIONAL
		%Appearance.flip_h = false
	else:
		%Appearance.frame = Frame.LEFT_AND_RIGHT
		%Appearance.flip_h = direction == Enums.LookAtSide.RIGHT


func _on_area_2d_body_entered(_body: Node2D) -> void:
	update_label_visiblity()


func _on_area_2d_body_exited(_body: Node2D) -> void:
	update_label_visiblity()


func update_label_visiblity() -> void:
	$LabelContainer.visible = !$Area2D.get_overlapping_bodies().is_empty()


func update_label_text() -> void:
	%Label.text = text
