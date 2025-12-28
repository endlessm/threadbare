# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AllHooked
@export var cables_to_turn_on: Array[Node2D]


func _ready() -> void:
	super._ready() 
	all_hooked.connect(_on_all_hooked)

func _on_all_hooked() -> void:
	for c in cables_to_turn_on:
		if c.has_method("turn_on"):
			c.turn_on()

func _process(delta: float) -> void:
	pass
