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

## Maximum offset allowed between the desired and existing screen position.
@export var max_offset_allowed: float = 100.0

## Used to limit the rate at which [method Node._process] is called.
var _update_time: float = 0

## Used to distinguish the first update.
var _first_update: bool = true

## Tween to fade in the label container.
var _fadein_tween: Tween

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

	_update_time -= _delta

	if _update_time > 0.0:
		return

	var new_position := get_global_transform_with_canvas().origin - (label_container.size / 2.0)
	var distance_squared := (label_container.global_position - new_position).length_squared()

	if distance_squared < max_offset_allowed * max_offset_allowed:
		return

	# Next update is inversely proportional to the distance in the screen.
	# In other words, the label will jump from one screen position to the other faster if it's far,
	# and will take more time to update if it's closer.
	_update_time = clamp(2000.0 / distance_squared, 0.1, 2.0)
	if _fadein_tween:
		_fadein_tween.kill()
	_fadein_tween = create_tween()
	if label_container.visible and not _first_update:
		# Duplicate the label node in the current position to fade out:
		var old_label_container := label_container.duplicate()
		label_container.get_parent().add_child(old_label_container)
		var fadeout_tween := create_tween()
		fadeout_tween.tween_property(
			old_label_container, "modulate", Color.TRANSPARENT, _update_time
		)
		fadeout_tween.tween_callback(old_label_container.queue_free)
	label_container.modulate = Color.TRANSPARENT
	_fadein_tween.tween_property(label_container, "modulate", Color.WHITE, _update_time)
	label_container.global_position = new_position
	_first_update = false


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
	_update_time = 0
	_first_update = true
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
