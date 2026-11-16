# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Parallax2D

@export_tool_button("Random Clouds") var randomize_button: Callable = randomize_effect

@export var _seed: int:
	set = _set_seed

var texture: NoiseTexture2D
var noise: FastNoiseLite
var tween: Tween

@onready var color_rect: ColorRect = %ColorRect


func _set_seed(new_seed: int) -> void:
	_seed = new_seed
	if noise:
		noise.seed = _seed
		await texture.changed


func _ready() -> void:
	texture = (color_rect.material as ShaderMaterial).get_shader_parameter("shadow_texture")
	noise = texture.noise
	_set_seed(_seed)


func randomize_effect() -> void:
	await _set_seed(randi())


func fade_in(duration: float = 1) -> void:
	if tween:
		tween.kill()
	color_rect.modulate = Color.BLACK
	visible = true
	tween = create_tween()
	tween.tween_property(color_rect, "modulate", Color.WHITE, duration)
	await tween.finished


func fade_out(duration: float = 1) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(color_rect, "modulate", Color.BLACK, duration)
	await tween.finished
	visible = false
