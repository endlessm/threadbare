# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AudioStreamPlayer
@export var volumen:float
func _ready() -> void:
	self.volume_db = volumen 
