# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## This is set in menu to tell whether it should start enabled or disabled
@export var is_enabled: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.enabled = is_enabled;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Enables and disables the tile layer whenever the lever is toggled
func _on_repellable_lever_toggled(is_on: bool) -> void:
	if is_on:
		self.enabled = not is_enabled;
	else:
		self.enabled = is_enabled;
