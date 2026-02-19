# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Parallax2D

@export_tool_button("Random Fog") var randomize_button: Callable = randomize

@export var _seed: int:
	set = _set_seed

var texture: NoiseTexture2D
var noise: FastNoiseLite

@onready var color_rect: ColorRect = %ColorRect


func _set_seed(new_seed: int) -> void:
	_seed = new_seed
	if noise:
		noise.seed = _seed
		await texture.changed


func _ready() -> void:
	texture = (color_rect.material as ShaderMaterial).get_shader_parameter("fog_texture")
	noise = texture.noise
	_set_seed(_seed)


func randomize() -> void:
	await _set_seed(randi())
