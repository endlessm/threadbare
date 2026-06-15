# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

@export_multiline var text: String = "":
	set(a_text):
		text = a_text
		update_label_text()

@export_range(50,80) var Radius:float = 70:
	set(setRadius):
		Radius = setRadius
		update_radius()
		
func _ready() -> void:
	update_label_text()
	if Engine.is_editor_hint():
		return
	update_label_visiblity()
	animated_sprite_2d.play(animated_sprite_2d.animation)



func _on_area_2d_body_entered(_body: Node2D) -> void:
	update_label_visiblity()


func _on_area_2d_body_exited(_body: Node2D) -> void:
	update_label_visiblity()


func update_label_visiblity() -> void:
	$LabelContainer.visible = !$Area2D.get_overlapping_bodies().is_empty()


func update_label_text() -> void:
	%Label.text = text

func update_radius() -> void:
	%CollisionShape2D.shape.radius = Radius
