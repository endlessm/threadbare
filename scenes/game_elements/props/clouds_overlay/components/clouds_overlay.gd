# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends ColorRect

@export var wind_direction: Vector2 = Vector2(1.0, 0.5)
@export_range(0, 50, 0.1) var wind_speed: float = 10

@export_range(0, 1, 0.01) var cloud_density: float = 0.2:
	set(val):
		cloud_density = val
		update_noise_color_ramp()
@export_range(0, 1, 0.01) var cloud_fluffyness: float = 0.3:
	set(val):
		cloud_fluffyness = val
		update_noise_color_ramp()
@export_range(0, 1, 0.01) var cloud_opacity: float = 0.15:
	set(val):
		cloud_opacity = val
		update_noise_color_ramp()

var current_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		global_position = get_viewport().get_camera_2d().get_screen_center_position() - size / 2
	current_offset += wind_direction.normalized() * wind_speed * delta
	material.set_shader_parameter("offset", current_offset)


func update_noise_color_ramp() -> void:
	var new_color_ramp: Gradient = Gradient.new()
	new_color_ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT

	new_color_ramp.set_color(0, Color(0, 0, 0, 0))
	new_color_ramp.set_color(1, Color(0, 0, 0, cloud_opacity))

	var cloud_start_point = 1 - cloud_density
	var cloud_end_point = cloud_start_point - cloud_fluffyness * (1 - cloud_start_point)

	new_color_ramp.add_point(cloud_start_point, Color(0, 0, 0, cloud_opacity))
	new_color_ramp.add_point(cloud_end_point, Color(0, 0, 0, cloud_opacity / 2))

	var noise_texture: NoiseTexture2D = material.get_shader_parameter("cloud_texture")
	noise_texture.color_ramp = new_color_ramp
