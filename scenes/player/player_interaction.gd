# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerInteraction
extends Node2D

var is_interacting: bool:
	get = _get_is_interacting

@onready var interact_ray: RayCast2D = %InteractRay
@onready var interact_marker: Marker2D = %InteractMarker
@onready var interact_label: InteractLabel = %InteractLabel


func _get_is_interacting() -> bool:
	return not interact_ray.enabled


func _ready() -> void:
	var current_scene: Node = get_tree().current_scene
	var screen_overlay: CanvasLayer = current_scene.get_node_or_null("ScreenOverlay")
	if not screen_overlay:
		push_error("ScreenOverlay not found in current scene.")
		return
	interact_label.reparent(screen_overlay)


func _process(_delta: float) -> void:
	if is_interacting:
		return
	var interact_area: InteractArea = interact_ray.get_interact_area()

	var label_offset: Vector2 = Vector2(interact_label.size.x / 2, interact_label.size.y)
	interact_label.position = (
		interact_marker.get_global_transform_with_canvas().origin - label_offset
	)

	if not interact_area:
		interact_label.visible = false
		return

	if %PlayerController.is_action_just_released(&"ui_accept"):
		interact_area.interaction_ended.connect(_on_interaction_ended, CONNECT_ONE_SHOT)
		interact_area.start_interaction(interact_ray.target_position.x < 0)
		interact_ray.enabled = false
		interact_label.visible = false
	else:
		interact_label.visible = true
		interact_label.label_text = interact_area.action


func _on_interaction_ended() -> void:
	interact_ray.enabled = true
