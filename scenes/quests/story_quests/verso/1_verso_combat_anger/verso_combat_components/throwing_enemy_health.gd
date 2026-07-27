# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends ThrowingEnemy

signal Defeated
	
func _on_got_hit(body: Node2D) -> void:
	super(body)
	Defeated.emit()
	remove()
