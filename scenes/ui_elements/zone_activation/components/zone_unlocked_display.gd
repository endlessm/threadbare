# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CanvasLayer

@export_tool_button("Anchor to top") var to_top_editor_button: Callable = anchor_to_top
@export_tool_button("Anchor to bottom") var to_bottom_editor_button: Callable = anchor_to_bottom

@onready var margin_container: MarginContainer = %MarginContainer
@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _is_player_at_bottom() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return false
	return CameraUtilities.is_node_at_bottom(player, 2 / 3.0)


## Anchor container to top:
func anchor_to_top() -> void:
	margin_container.anchor_top = 0
	margin_container.anchor_bottom = 0
	margin_container.offset_top = 0
	margin_container.offset_bottom = -4096
	margin_container.grow_vertical = Control.GROW_DIRECTION_END


## Anchor container to bottom:
func anchor_to_bottom() -> void:
	margin_container.anchor_top = 1
	margin_container.anchor_bottom = 1
	margin_container.offset_top = 4096
	margin_container.offset_bottom = 0
	margin_container.grow_vertical = Control.GROW_DIRECTION_BEGIN


func stop_animation() -> void:
	if animation_player.is_playing():
		animation_player.stop()


func animate(zone_name: String) -> void:
	stop_animation()
	# Assumes that the container is anchored to the bottom by default:
	if _is_player_at_bottom():
		anchor_to_top()
	label.text = zone_name
	animation_player.play(&"default")
