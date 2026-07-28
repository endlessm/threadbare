# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.enabled = false;
	# TODO: Replace it with void tiles


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_repellable_lever_toggled(is_on: bool) -> void:
	if is_on:
		self.enabled = true;
	else:
		self.enabled = false;
