# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var spirit_thread: CollectibleItem = %SpiritThread
@onready var color_rect: ColorRect = $HUD/ColorRect


func _ready() -> void:
	GameState.item_collected.connect(_on_item_collected)

	var shader_material := color_rect.material as ShaderMaterial
	shader_material.set_shader_parameter("saturation", 0.0)


func _on_item_collected(_item) -> void:
	var shader_material := color_rect.material as ShaderMaterial
	shader_material.set_shader_parameter("saturation", 1.0)
