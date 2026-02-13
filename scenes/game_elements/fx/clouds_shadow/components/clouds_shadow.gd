# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Parallax2D

@export_tool_button("Random Clouds") var randomize_button: Callable = randomize

var texture: NoiseTexture2D
var noise: FastNoiseLite

@onready var color_rect: ColorRect = %ColorRect


func _ready() -> void:
	texture = (color_rect.material as ShaderMaterial).get_shader_parameter("shadow_texture")
	noise = texture.noise


func randomize() -> void:
	noise.seed = randi()
	await texture.changed
