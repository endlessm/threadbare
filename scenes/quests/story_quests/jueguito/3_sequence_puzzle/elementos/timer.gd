# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Timer

@onready var time_label = $"../CanvasLayer/Label"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_minijuego3_timeout)
	

func _on_minijuego3_timeout() -> void:
	for p: Player in get_tree().get_nodes_in_group(&"player"):
		p.defeat()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var remaining = int(time_left)
	var minutes = remaining / 60
	var seconds = remaining % 60
	var ms = int((time_left - int(time_left)) * 1000)
	
	time_label.text = "%02d:%02d:%03d" % [minutes, seconds, ms]
