# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends FillingBarrel

signal hp_changed(current_damage)
@onready var hit_sound = $AudioStreamPlayer

func increment(by: int = 1) -> void:
	super.increment(by)
	
	if hit_sound:
		hit_sound.play()
	emit_signal("hp_changed", _amount)
