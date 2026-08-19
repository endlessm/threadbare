# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## The four bridge TileMapLayers.
@export var bridge_1: TileMapLayer
@export var bridge_2: TileMapLayer
@export var bridge_3: TileMapLayer
@export var bridge_4: TileMapLayer


## Makes sure all bridges are visible and enabled.
func _ready() -> void:
	show_bridge(bridge_1)
	show_bridge(bridge_2)
	show_bridge(bridge_3)
	show_bridge(bridge_4)


## Tells when step_index was completed.
func _on_sequence_puzzle_step_solved(step_index: int) -> void:
	if step_index == 0:
		hide_bridge(bridge_1)
	elif step_index == 1:
		hide_bridge(bridge_2)
	elif step_index == 2:
		hide_bridge(bridge_3)
	elif step_index == 3:
		hide_bridge(bridge_4)


## Makes a bridge visible and enables collision.
func show_bridge(bridge: TileMapLayer) -> void:
	if bridge == null:
		return

	bridge.enabled = true
	bridge.visible = true


## Hides bridge and removes collision.
func hide_bridge(bridge: TileMapLayer) -> void:
	if bridge == null:
		return

	bridge.enabled = false
	bridge.visible = false
