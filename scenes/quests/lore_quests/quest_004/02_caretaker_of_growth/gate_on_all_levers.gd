# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Opens a target (Door / Toggleable) ONLY when ALL assigned levers are active.
## Used for "turn on all levers to open the gate" puzzles.

## Array of levers (lever.tscn) that must be turned on.
@export var levers: Array[Node]
## Target node to trigger (a Door or Toggleable with set_toggled).
@export var target: Node


func _ready() -> void:
	for lever in levers:
		if lever and lever.has_signal(&"toggled"):
			lever.toggled.connect(_on_lever_toggled)
	_check()


func _on_lever_toggled(_is_on: bool) -> void:
	_check()


func _check() -> void:
	if not is_instance_valid(target) or not target.has_method("set_toggled"):
		return
	for lever in levers:
		if not is_instance_valid(lever) or not lever.is_on:
			target.set_toggled(false)
			return
	target.set_toggled(true)
