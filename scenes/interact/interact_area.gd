# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InteractArea
extends Area2D

signal interaction_started(from_right: bool)
signal interaction_ended

@export var action: String = "Talk"


func start_interaction(from_right: bool) -> void:
	interaction_started.emit(from_right)


func end_interaction() -> void:
	interaction_ended.emit()
