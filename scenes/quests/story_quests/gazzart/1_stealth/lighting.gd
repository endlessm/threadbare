# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ColorRect
class_name lighting

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var light_positions = _get_light_positions()
	material.set_shader_parameter("number_of_lights", light_positions.size())
	material.set_shader_parameter("lights", light_positions)
	
func _get_light_positions():
	return get_tree().get_nodes_in_group("light").map(
		func(light: Node2D):
			return light.get_global_transform_with_canvas().origin
	)
