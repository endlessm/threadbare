# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D


# Called when the node enters the scene tree for the first time.
func _on_body_entered(body: Node2D) -> void:
	  # Replace with function body.
	if body is Player:
		body.defeat(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
