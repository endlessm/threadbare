# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## This is set in menu to tell whether it should start enabled or disabled.
@export var is_enabled: bool


## Automatically sets the layer visibility at the start.
func _ready() -> void:
	self.enabled = is_enabled


## Enables and disables the tile layer whenever the lever is toggled.
func _on_repellable_lever_toggled(is_on: bool) -> void:
	if is_on:
		self.enabled = not is_enabled
	else:
		self.enabled = is_enabled
