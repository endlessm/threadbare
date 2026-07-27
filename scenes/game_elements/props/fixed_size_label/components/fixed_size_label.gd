# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FixedSizeLabel
extends Control

## This is a label meant to be used along with props (game elements), but whose
## size and position doesn't depend on the camera's zoom.[br]
## It automatically searches a CanvasLayer called ScreenOverlay and attaches
## the label itself to it.

@export var label_text: String:
	set = _set_label_text

@onready var label: Label = %Label
## The node that actually holds the label.
@onready var label_container: PanelContainer = %LabelContainer


func _set_label_text(new_text: String) -> void:
	label_text = new_text
	if not is_node_ready():
		return
	label.text = tr(new_text)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		label_container.global_position = global_position - (label_container.size / 2.0)
		return

	label_container.global_position = (
		get_global_transform_with_canvas().origin - (label_container.size / 2.0)
	)


func _ready() -> void:
	_set_label_text(label_text)

	if Engine.is_editor_hint():
		return

	visibility_changed.connect(self.on_visibility_changed)
	var screen_overlay: CanvasLayer = get_tree().current_scene.get_node_or_null("ScreenOverlay")
	if not screen_overlay:
		push_error("ScreenOverlay not found in current scene.")
		return
	label_container.reparent.call_deferred(screen_overlay)


func on_visibility_changed() -> void:
	label_container.visible = is_visible_in_tree()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return

	if label_container:
		label_container.queue_free()


func _on_label_resized() -> void:
	if not is_node_ready():
		return
	# TODO: Workaround for https://github.com/godotengine/godot/issues/100626
	label_container.reset_size()
